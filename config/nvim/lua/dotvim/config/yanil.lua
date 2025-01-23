local Levels = vim.log.levels

local dotutil = require('dotvim.util')

local yanil = require('yanil')
local git = require('yanil/git')
local decorators = require('yanil/decorators')
local canvas = require('yanil/canvas')

local mini_icons = require('mini.icons')

local vim_notify = function(msg, level, opts)
    opts = opts or {}
    opts.title = 'Yanil'
    vim.notify(msg, level, opts)
end

local a = dotutil.async()

local M = {}

---@diagnostic disable-next-line: unused-local
local function git_diff(_tree, node)
    local diff = git.diff(node)
    if not diff then
        return
    end

    local winnr, bufnr = dotutil.open_floating_window()
    vim.wo[winnr].cursorline = true
    vim.wo[winnr].winhl = 'NormalFloat:'
    vim.wo[winnr].number = true
    vim.api.nvim_win_set_config(winnr, {
        border = 'rounded',
        title = 'Diff Patch',
        title_pos = 'center',
    })

    -- content
    vim.bo[bufnr].filetype = 'diff'
    vim.bo[bufnr].bufhidden = 'wipe'
    vim.bo[bufnr].swapfile = false
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff)

    vim.api.nvim_buf_create_user_command(bufnr, 'Apply', function()
        require('yanil/git').apply_buf(bufnr)
    end, { desc = 'apply the patch in this buffer' })

    vim.keymap.set('n', '<leader>a', '<cmd>Apply<CR>', { buffer = bufnr })
end

local find_file = function(tree, node)
    local cwd = node:is_dir() and node.abs_path or node.parent.abs_path
    local on_confirm = function(_, item)
        local path = item.file
        if not path or path == '' then
            return
        end
        path = vim.fs.joinpath(cwd, path)

        local target = tree.root:find_node_by_path(path)
        if not target then
            vim_notify('file "' .. path .. '" is not found or ignored', Levels.WARN)
            return
        end
        tree:go_to_node(target)
    end

    ---@diagnostic disable-next-line: missing-fields
    require('snacks.picker').files({
        cwd = cwd,
        actions = {
            confirm = { 'close', on_confirm },
        },
    })
end

local create_node = a.wrap(function(tree, node)
    node = node:is_dir() and node or node.parent
    local name = a.ui
        .input({
            prompt = node.abs_path,
        })
        .await()
    if not name or name == '' then
        return
    end

    local path = node.abs_path .. name
    if tree.root:find_node_by_path(path) then
        vim_notify('path "' .. path .. '" is already exists', Levels.WARN)
        return
    end

    local dir = vim.fn.fnamemodify(path, ':h')
    local res = a.system({ 'mkdir', '-p', dir }).await()

    if res.code ~= 0 then
        vim_notify('mkdir failed: ' .. (res.stderr or res.stdout or ''), Levels.ERROR)
        return
    end
    if not vim.endswith(path, '/') then
        res = a.system({ 'touch', path }).await()

        if res.code ~= 0 then
            vim_notify('touch file failed: ' .. (res.stderr or res.stdout or ''), Levels.ERROR)
            return
        end
    end

    a.schedule().await()

    tree:force_refresh_node(node)
    git.update(tree.cwd)

    local new_node = tree.root:find_node_by_path(path)
    if not new_node then
        vim_notify('create node failed', Levels.WARN)
        return
    end
    tree:go_to_node(new_node)
end)

local function clear_buffer(path)
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if path == vim.api.nvim_buf_get_name(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
            return
        end
    end
end

local delete_node = a.wrap(function(tree, node)
    if node == tree.root then
        vim_notify('You can NOT delete the root', Levels.WARN)
        return
    end
    if node:is_dir() then
        node:load()
    end

    if node:is_dir() and #node.entries > 0 then
        local answer = a.ui
            .input({
                prompt = 'Directory is not empty. Are you sure? ',
                default = 'No',
            })
            .await()
        if not answer or answer:lower() ~= 'yes' then
            return
        end
    end

    local res = a.system({ 'rm', '-rf', node.abs_path }).await()
    if res.code ~= 0 then
        a.api.nvim_err_writeln('delete node failed:', (res.stderr or res.stdout or ''))
        return
    end

    a.schedule().await()

    clear_buffer(node.abs_path)
    local parent = node.parent
    tree:force_refresh_node(parent)
    git.update(tree.cwd)
end)

local icon_decorator
if (vim.env.YANIL_BUBBLE or '0') == '1' then
    icon_decorator = function(node)
        if not node.parent then
            local text = node.is_open and '' or ''
            return text, 'YanilTreeDirectory'
        end

        if node:is_dir() then
            local text = node.is_open and '' or ''
            return text, node:is_link() and 'YanilTreeLink' or 'YanilTreeDirectory'
        end

        local _, hl = mini_icons.get('file', node.name)
        return '', hl
    end
else
    icon_decorator = function(node)
        if not node.parent then
            local text = '󰙅'
            return text, 'YanilTreeDirectory'
        end
        if node:is_dir() then
            local text = node.is_open and '' or ''
            return text, node:is_link() and 'YanilTreeLink' or 'YanilTreeDirectory'
        end

        local icon, hl = mini_icons.get('file', node.name)
        if icon then
            return icon, hl
        end

        return ''
    end
end

function M.setup()
    yanil.setup()

    local tree = require('yanil/sections/tree'):new()

    tree:setup({
        draw_opts = {
            decorators = {
                decorators.pretty_indent_with_git,
                icon_decorator,
                decorators.space,
                decorators.default,
                decorators.executable,
                decorators.readonly,
                decorators.link_to,
            },
        },
        filters = {
            function(name)
                local patterns = { '^%.git$', '%.pyc', '^__pycache__$', '^%.idea$', '^%.iml$', '^%.DS_Store$', '%.o$', '%.cmd$' }
                for _, pat in ipairs(patterns) do
                    if string.find(name, pat) then
                        return true
                    end
                end
            end,
        },
        keymaps = {
            [']c'] = git.jump_next,
            ['[c'] = git.jump_prev,
            gd = git_diff,
            ['<A-/>'] = find_file,
            ['<A-a>'] = create_node,
            ['<A-x>'] = delete_node,
            ['o'] = function(self, node)
                node = node:is_dir() and node or node.parent

                self:refresh(node, {}, function()
                    node:toggle()
                end)

                self:go_to_node(node)
            end,
        },
    })

    canvas.register_hooks({
        on_enter = function()
            git.update(tree.cwd)
            vim.keymap.set('n', 'q', function()
                vim.cmd('quit')
            end, { buffer = canvas.bufnr })
        end,
    })

    canvas.setup({
        sections = {
            tree,
        },
        autocmds = {
            {
                event = 'User',
                pattern = 'YanilGitStatusChanged',
                cmd = function()
                    git.refresh_tree(tree)
                end,
            },
        },
    })

    vim.keymap.set({ 'n', 'i' }, '<A-f>', function()
        local path = vim.fn.expand('%:p')
        local target = tree.root:find_node_by_path(path)
        if not target then
            vim_notify('file "' .. path .. '" is not found or ignored', Levels.WARN)
            return
        end
        tree:go_to_node(target)
    end, {
        desc = '[Yanil] focus current file in tree',
    })
end

return M
