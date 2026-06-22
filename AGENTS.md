# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.

## What this is

A personal dotfiles repository managed by [dotbot](https://github.com/anishathalye/dotbot)
(vendored as a git submodule at `dotbot/`). Files in this repo are symlinked into `$HOME`
and `~/.config` rather than copied. Supports both macOS (Darwin) and Linux, with
OS-conditional links and config includes.

## Install / apply changes

```sh
./install          # idempotent; runs dotbot to (re)create symlinks and run setup shell steps
```

`install.conf.yaml` is the source of truth for what gets linked and what setup commands run.
After editing it, re-run `./install` to apply. Key behaviors it drives:

- `link:` maps repo paths to symlink targets (e.g. `tmux.conf` -> `~/.tmux.conf`,
  `config/nvim` -> `~/.config/nvim`). Linux-only links use an `if: '[ \`uname\` = Linux ]'` guard.
- `shell:` steps wire up things symlinks can't: include `config/git/config` into the global
  gitconfig, append an SSH `Include`, generate OS-specific `os.conf`/`os.config` files for
  kitty/ghostty, install fonts, and fetch the bat theme.

Because configs are symlinked, edits to files under `config/` take effect immediately without
re-running `./install` (only changes to the link map or setup steps require it).

## Linting

Lint runs in CI (`.github/workflows/lint.yml`) and via pre-commit; both are scoped to `config/nvim/`:

- **luacheck** — config in `.luacheckrc` (Lua 5.1 + nvim globals).
- **stylua** — config in `stylua.toml` and `config/nvim/stylua.toml` (4-space indent,
  150 col, single quotes).
- Run pre-commit hooks locally: `pre-commit run --all-files`.

## Neovim config (`config/nvim/`)

This is the largest and most actively developed component. It has its own detailed guide in
`config/nvim/AGENTS.md` — **read it before working on nvim**. Key points:

- Lua config under the `dotvim` namespace; entry point `init.lua` requires nvim >= 0.12.
- Plugins managed by lazy.nvim (`lua/dotvim/lazy.lua`), specs in `lua/dotvim/plugins/`,
  lockfile `lazy-lock.json`.
- Feature flags (`lua/dotvim/features.lua`) read `NVIM_<FEATURE>_ENABLED` env vars; e.g.
  setting `features.mini` switches plugin loading from `dotvim.plugins` to `dotvim.mini`.
- Tests use mini.test: `cd config/nvim && make test` (all) or
  `make test_file FILE=tests/test_git.lua` (single). Bootstrap is `scripts/minimal_init.lua`.
- All Lua functions/types must carry LuaCATS annotations; nvim commits use scope `nvim`.

## Other components

- `zshrc` — zsh with zinit plugin manager and powerlevel10k; sources `~/.zshrc.before` first.
- `tmux.conf`, `config/zellij/` — terminal multiplexers.
- `config/ghostty/`, `config/kitty/` — terminal emulators; OS-specific include generated at install.
- `scripts/` — standalone helper scripts symlinked into `~/.local/bin/` (e.g. `llm-cli`,
  `osc52-yank`, `secret-decode`, `pi-panes`).
- `Brewfile` — Homebrew bundle; regenerate with `./dump_brew.sh`.

## Conventions

- Commit messages use a `type(scope)` prefix matching the area changed, e.g. `feat(nvim): ...`,
  `feat(zsh): ...` (see git log).
- Do not commit unless explicitly asked.
