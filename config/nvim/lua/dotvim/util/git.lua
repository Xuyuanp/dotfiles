local M = {}

local a = require('dotvim.util.async')
local icons = require('dotvim.settings').icons.git

local choices = {
    {
        icon = icons.branch,
        args = { 'symbolic-ref', '-q', '--short', 'HEAD' },
    },
    {
        icon = icons.tag,
        args = { 'describe', '--tags', '--exact-match' },
    },
    {
        icon = icons.commit,
        args = { 'rev-parse', '--short', 'HEAD' },
    },
}

---@param bufnr number
---@param root? string
local load_head = a.wrap(function(bufnr, root)
    for _, choice in ipairs(choices) do
        local args = { 'git' }
        if root then
            vim.list_extend(args, { '-C', root })
        end
        vim.list_extend(args, choice.args)

        local res = a.system(args, { text = true }).await()
        if res.code == 0 then
            local head = vim.trim(res.stdout)
            vim.b[bufnr].dotvim_git_head = choice.icon .. ' ' .. head

            a.schedule().await()
            vim.api.nvim_exec_autocmds('User', {
                pattern = 'DotVimGitHeadUpdate',
                data = { bufnr = bufnr, head = head, icon = choice.icon },
            })
            return
        end
    end
end)

function M.load_head(bufnr, root)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    load_head(bufnr, root)
end

local function system(cmd)
    return vim.trim(vim.fn.system(cmd))
end

function M.remote_link()
    local root_dir = system({ 'git', 'rev-parse', '--show-toplevel' })
    local branch = system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' })
    local url = system({ 'git', 'remote', 'get-url', 'origin' })
    if url:match('^git@') then
        url = url:gsub(':', '/')
        url = url:gsub('^git@', 'https://')
    end
    local host = url:gsub('%.git$', '')
    local file_path = vim.fn.expand('%:p'):sub(#root_dir + 2)
    local line = vim.fn.line('.')
    local link = string.format('%s/blob/%s/%s#L%d', host, branch, file_path, line)

    local on_choice = function(choice)
        if not choice then
            return
        end
        if choice == 'Copy' then
            vim.fn.setreg('+', link)
            vim.fn.setreg('*', link)
            vim.notify('Copied to clipboard: ' .. link, vim.log.levels.INFO)
        elseif choice == 'Open' then
            vim.ui.open(link)
        end
    end
    vim.ui.select({ 'Open', 'Copy' }, {
        prompt = link,
    }, on_choice)
end

function M.gitlab_mr()
    local mr_data = system({ 'glab', 'mr', 'view', '-F', 'json' })
    if vim.v.shell_error ~= 0 then
        vim.notify('Failed to get MR data', vim.log.levels.WARN)
        return
    end
    local mr = vim.json.decode(mr_data)
    return mr
end

---@param path string absolute file or directory path
---@return string|nil repo_root absolute path to the git repository root containing `path`, or nil if `path` is not inside a git repo / does not exist
function M.root(path)
    local stat = vim.uv.fs_stat(path)
    if not stat then
        return nil
    end

    -- For a directory, start the discovery inside it; for a file, use its
    -- containing directory. Taking :h unconditionally is wrong when `path`
    -- is itself a directory (especially the repo root), because the parent
    -- may sit outside any git repository.
    local git_cwd = stat.type == 'directory' and path or vim.fn.fnamemodify(path, ':h')
    local root_res = vim.system({ 'git', '-C', git_cwd, 'rev-parse', '--show-toplevel' }):wait()
    if root_res.code ~= 0 then
        return nil
    end
    return vim.trim(root_res.stdout)
end

---@param path string absolute file or directory path
---@return string[]|nil diff lines, including tracked changes and untracked files under path
function M.diff(path)
    local root = M.root(path)
    if not root then
        return
    end

    local lines = {}

    -- Tracked changes under path (empty if path only contains untracked files)
    vim.list_extend(
        lines,
        vim.fn.systemlist({
            'git', '-C', root, 'diff', '--patch', '--no-color', '--diff-algorithm=default', path,
        })
    )

    -- Untracked (non-ignored) files under path -- each rendered as a new-file diff
    local untracked = vim.fn.systemlist({
        'git', '-C', root, 'ls-files', '--others', '--exclude-standard', path,
    })
    for _, rel in ipairs(untracked) do
        if rel ~= '' then
            vim.list_extend(
                lines,
                vim.fn.systemlist({
                    'git', '-C', root, 'diff', '--no-index', '--patch', '--no-color', '/dev/null', rel,
                })
            )
        end
    end

    if #lines == 0 then
        return
    end

    return lines
end

--- Open a floating window showing the diff for `path`, with an :Apply command
--- that stages the (possibly edited) patch via `git apply --cached`.
---@param path string absolute file or directory path
---@param opts? { on_apply?: fun() }
function M.show_diff(path, opts)
    opts = opts or {}

    local diff = M.diff(path)
    if not diff then
        return
    end

    local dotutil = require('dotvim.util')
    local winnr, bufnr = dotutil.open_floating_window()
    vim.wo[winnr].cursorline = true
    vim.wo[winnr].winhl = 'NormalFloat:'
    vim.wo[winnr].number = true
    vim.api.nvim_win_set_config(winnr, {
        title = 'Diff Patch',
        title_pos = 'center',
    })

    -- content
    vim.bo[bufnr].filetype = 'diff'
    vim.bo[bufnr].bufhidden = 'wipe'
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].undolevels = -1
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff)
    vim.bo[bufnr].undolevels = 1000

    vim.api.nvim_buf_create_user_command(bufnr, 'Apply', function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if not lines or #lines == 0 or (#lines == 1 and lines[1] == '') then
            vim.cmd('q')
            return
        end
        -- Ensure trailing newline: git apply expects POSIX text input.
        -- concat(['a','b'], '\n') = "a\nb" but concat(['a','b',''], '\n') = "a\nb\n"
        if lines[#lines] ~= '' then
            table.insert(lines, '')
        end
        local patch = table.concat(lines, '\n')

        local root = M.root(path)
        if not root then
            vim.notify('Not in a git repository', vim.log.levels.WARN)
            return
        end

        local res = vim.system({ 'git', '-C', root, 'apply', '--cached' }, { stdin = patch }):wait()
        if res.code ~= 0 then
            vim.notify(
                string.format('git apply failed: %s', res.stderr or 'unknown'),
                vim.log.levels.ERROR
            )
            return
        end

        vim.cmd('q')
        if opts.on_apply then
            opts.on_apply()
        end
    end, { desc = 'apply the patch in this buffer' })

    vim.keymap.set('n', '<leader>a', '<cmd>Apply<CR>', { buffer = bufnr })
end

return M
