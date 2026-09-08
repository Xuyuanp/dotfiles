# Handoff: migrate `dotvim.util.async` to `vim.async`

This document guides the migration of the remaining callback-style async code in
this neovim config from the custom library `dotvim.util.async` to the built-in
`vim.async` (structured concurrency API, available in nvim nightly 0.13).

## Status

| Item | State |
|---|---|
| `lua/dotvim/util/git.lua` | **Done** — migrated, committed (`feat(nvim): migrate git.lua to vim.async`). Use it as the reference example. |
| `lua/dotvim/util/nerdfonts.lua` | Pending |
| `lua/dotvim/config/neotest.lua` | Pending |
| `lua/dotvim/config/dap.lua` | Pending |
| `lua/dotvim/config/lsp/keymaps.lua` | Pending |
| `lua/dotvim/plugins/langs.lua` | Pending |
| `lua/dotvim/util/async/*` | Delete at the end (library itself) |
| `lua/dotvim/util/init.lua` | Remove the `M.async()` accessor at the end |

## Requirement

`vim.async` exists only in nvim nightly (0.13-dev). This config pins nvim via
mise (`config/mise/mise.toml`). Do not port this work to stable.

## Remaining usage per file

- `nerdfonts.lua` — `a.wrap(...)` entry point, `a.uv().read_file(path)`,
  `a.schedule().await()`, `a.ui.select(...).await()`.
- `neotest.lua` — `a.wrap(...)`, `a.ui.select(...).await()`.
- `dap.lua` — `a.wrap(...)`, `a.ui.input(...).await()`, `a.ui.select(...).await()`.
- `lsp/keymaps.lua` — `a.wrap(...)`, `a.ui.select(...).await()`.
- `plugins/langs.lua` — `a.wrap(...)`, `a.ui.select(...).await()`, `a.schedule().await()`.

## Idiom mapping

| Old idiom | New idiom |
|---|---|
| `local f = a.wrap(function() ... end)` (launched from sync code) | `local function f() async.run(function() ... end):raise_on_error() end` — or a named async fn: `async.run(do_work, arg1, arg2):raise_on_error()` |
| `a.ui.select(items, opts).await()` | `async.await(3, vim.ui.select, items, opts)` — returns the choice |
| `a.ui.input(opts).await()` | `async.await(2, vim.ui.input, opts)` — returns the input string |
| `a.schedule().await()` | `async.await(vim.schedule)` — hop to the main loop |
| `a.system(args, opts).await()` | `async.await(3, vim.system, args, opts)` — returns `vim.SystemCompleted` (see traps) |
| `a.uv().fs_stat(path).await()` | `async.await(2, vim.uv.fs_stat, path)` — returns `err, stat` |
| `a.uv().fs_open(path, 'r', 438).await()` | `async.await(4, vim.uv.fs_open, path, 'r', 438)` — returns `err, fd` |
| `a.uv().fs_fstat(fd).await()` | `async.await(2, vim.uv.fs_fstat, fd)` |
| `a.uv().fs_read(fd, size, 0).await()` | `async.await(4, vim.uv.fs_read, fd, size, 0)` — returns `err, data` |
| `a.uv().fs_close(fd).await()` | `async.await(2, vim.uv.fs_close, fd)` |
| `a.await_all(t1, t2)` | collect `async.run(...)` tasks and `async.pawait` each; use `async.iter(tasks)` for first-done |

The `argc` in `async.await(argc, func, ...)` is the 1-based position of the
callback argument. Callback arguments are returned **unchanged**, so
error-first callbacks still return `err, value`.

Do not use these forms from synchronous code:
- `async.sleep`
- `async.await`
- `async.timeout`

They require a task context ("Not in async context"). From sync code use
`async.run(...)` (top-level task, starts immediately) or `task:wait()`.

## Semantics to respect (traps)

1. **`await()` on a failed task poisons the awaiting task** — even inside
   `pcall`, the error is recorded and re-raises at the next finish. Use
   `async.pawait(task)` to observe a failure and continue.
2. **`Task:wait(ms)` raises `"timeout"` by design.** Wrap in `pcall` when
   probing.
3. **Ownership is fixed at creation.** `await(task)` only observes the result.
   Awaiting does not attach the task to the awaiter.
4. **Unhandled child failure fails the parent** and closes the remaining
   children. A parent finishes only after its attached children finish.
5. **Cancellation is cooperative.** `task:close()` delivers `'closed'` at the
   next checkpoint, and closes owned closable handles (timers, pipes) first.
   `async.is_closing()` is `false` at task start; it is only meaningful after a
   close request. Cleanup loops: `while not async.is_closing() do ... sleep(10) end`.
6. **`vim.system` callback form returns `vim.SystemCompleted`**, not
   `vim.SystemObj`. `SystemCompleted` has `code`, `signal`, `stdout?`,
   `stderr?`. `SystemObj` is only the handle (`pid`, `wait`, `kill`, `write`).
7. **`vim.async.wrap(argc, func)`** builds an async function that another task
   can await. It is **not** an entry point from sync code — `async.run` is.

## LuaCATS typing notes

- The `async.run` generic (`fun(...: T...): R...`) requires the async function
  to return a value. A function returning nothing triggers
  "Annotations specify that a return value is required here". Either return a
  value (e.g. `return head`) or annotate a named function `--- @return nil`.
- `async.await(...)` returns a tuple `R...`. Cast a single value like this —
  `@cast` before `select(1, ...)` fails:
  ```lua
  --- @param args string[]
  --- @param opts? table
  --- @return vim.SystemCompleted
  local function system_async(args, opts)
      local res = select(1, async.await(3, vim.system, args, opts or {}))
      --- @cast res vim.SystemCompleted
      return res
  end
  ```
- Type the boundary once in a small helper instead of casting at each use site.
- Some lua-language-server builds report `Cannot assign function to parameter
  string|T...` on every `async.run(fn, ...)` call. This is a known artifact of
  the runtime's `async.run` annotation; it is not fixable in this code.

## Reference example (committed)

`lua/dotvim/util/git.lua` shows the full pattern: a typed `system_async`
helper, a named async function returning a value, and a thin sync entry point:

```lua
local async = vim.async

--- @return vim.SystemCompleted
local function system_async(args, opts)
    local res = select(1, async.await(3, vim.system, args, opts or {}))
    --- @cast res vim.SystemCompleted
    return res
end

--- @return string|nil
local function do_load_head(bufnr, root)
    for _, choice in ipairs(choices) do
        local res = system_async(args, { text = true })
        if res.code == 0 then
            return head
        end
    end
    return nil
end

function M.load_head(bufnr, root)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    async.run(do_load_head, bufnr, root):raise_on_error()
end
```

## Verification method

Baseline first, then migrate, then run the same harness. Headless runs with the
config on the runtime path:

```sh
nvim --clean --headless -u NONE \
  --cmd "set rtp+=/Users/shawn/.dotfiles/config/nvim" \
  +"luafile /tmp/harness.lua" +qa!
```

Example harness pattern for UI-picker code cannot run headless (no UI); verify
the sync entry point and error behavior instead:

```lua
-- for async.run entries: assert the spawn completes and state updates
local task = async.run(function() ... end)
assert(task:wait(2000))
-- for error paths: expect pwait to return false without killing the task
local ok, err = async.pawait(async.run(function() error('boom') end))
assert(not ok and tostring(err):match('boom'))
```

For git-like flows use a real repo and check the produced values, as done for
`git.lua` (branch and detached-HEAD/tag scenarios, `DotVimGitHeadUpdate`
autocmd fired).

## Lint and commit rules

- Run from `config/nvim/`:
  ```sh
  luacheck --config ../../.luacheckrc lua/dotvim/<file>
  stylua --check --config-path stylua.toml lua/dotvim/<file>
  ```
  `stylua.toml` is the single canonical config (150 columns, single quotes,
  `collapse_simple_statement = 'Never'`). stylua 2.x discovers it per-file, but
  pass `--config-path` for determinism. Fix any diff with
  `stylua --config-path stylua.toml <file>`.
- Commit message: `feat(nvim): migrate <file> to vim.async`. One commit per
  file is fine. Do not mix unrelated formatting into migration commits; commit
  styling separately as `style(nvim): ...`.
- `vim.async` is unreleased nightly API. Expect upstream changes; fix call
  sites on nvim upgrades.

## Final step

When no file requires `dotvim.util.async` anymore:
1. Delete `lua/dotvim/util/async/` (`init.lua`, `uv.lua`).
2. Remove `M.async()` from `lua/dotvim/util/init.lua`.
3. `rg -n "dotvim.util.async|util.async|a\.(wrap|uv|ui|schedule|system)" lua/`
   must return nothing.
4. Commit `refactor(nvim): drop dotvim.util.async`.