---@param picker snacks.Picker
---@param item snacks.picker.Item
---@return snacks.picker.Item[]
local function get_siblings(picker, item)
    local siblings = vim.iter(picker.list.items)
        :filter(function(sib)
            return sib.parent == item.parent
        end)
        :totable()

    table.sort(siblings, function(a, b)
        return a.sort < b.sort
    end)
    return siblings
end

---@param picker snacks.Picker
---@param file string
local function goto_file(picker, file)
    local state = require('snacks.picker.source.explorer').get_state(picker)
    state:show(file)
end

---@param fn fun(siblings: snacks.picker.Item[], item: snacks.picker.Item): snacks.picker.Item
---@return fun(picker: snacks.Picker, item: snacks.picker.Item)
local function sibling_action(fn)
    return function(picker, item)
        local siblings = get_siblings(picker, item)
        local sib = fn(siblings, item)
        goto_file(picker, sib.file)
    end
end

local actions = {}

function actions.first(siblings)
    return siblings[1]
end

function actions.last(siblings)
    return siblings[#siblings]
end

function actions.prev(siblings, item)
    for idx, sib in ipairs(siblings) do
        if sib == item then
            return siblings[math.max(idx - 1, 1)]
        end
    end
end

function actions.next(siblings, item)
    for idx, sib in ipairs(siblings) do
        if sib == item then
            return siblings[math.min(idx + 1, #siblings)]
        end
    end
end

local function git_diff(path)
    local diff = vim.fn.systemlist({ 'git', 'diff', '--patch', '--no-color', '--diff-algorithm=default', path })
    if not diff then
        return
    end

    local winnr, bufnr = require('dotvim.util').open_floating_window()
    vim.wo[winnr].cursorline = true
    vim.wo[winnr].number = true
    vim.api.nvim_win_set_config(winnr, {
        border = 'rounded',
        title = 'Diff Patch',
        title_pos = 'center',
    })

    -- content
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, diff)
    vim.bo[bufnr].filetype = 'diff'

    -- idk why, but i have to set foldmethod later
    vim.defer_fn(function()
        vim.api.nvim_win_call(winnr, function()
            vim.wo.foldmethod = 'expr'
        end)
    end, 500)

    vim.api.nvim_buf_create_user_command(bufnr, 'Apply', function()
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if not lines or #lines == 0 or (#lines == 1 and lines[1] == '') then
            return
        end
        if lines[-1] ~= ' ' then
            table.insert(lines, ' ')
        end
        local patch = table.concat(lines, '\n')
        local res = vim.system({ 'git', 'apply', '--cache' }, {
            stdin = patch,
        }):wait()
        if res.code ~= 0 then
            vim.notify(string.format('git apply failed: %s', res.stderr or res.stdout or 'unknown'), vim.log.levels.ERROR)
        end

        vim.api.nvim_buf_delete(bufnr, { force = true })
    end, { desc = 'apply the patch in this buffer' })

    vim.keymap.set('n', '<leader>a', '<cmd>Apply<CR>', { buffer = bufnr })
end

return {
    {
        'folke/snacks.nvim',
        dependencies = {
            'folke/which-key.nvim',
            optional = true,
            opts_extend = { 'spec' },
            opts = {
                spec = {
                    { '<leader>p', group = 'picker', icon = { icon = '', color = 'green' } },
                },
            },
        },
        optional = true,
        keys = function()
            local prefix = '<leader>p'
            local keys = {
                { key = 'p', source = 'pickers' },
                { key = 'r', source = 'resume' },
                { key = 'f', source = 'files' },
                { key = 'b', source = 'buffers' },
                { key = 'g', source = 'grep' },
                { key = 'e', source = 'explorer' },
            }
            return vim.iter(keys)
                :map(function(k)
                    local lhs = prefix .. k.key
                    local rhs = function()
                        require('snacks.picker').pick(k.source)
                    end
                    local desc = '[Picker] ' .. (k.desc or k.source)
                    return { lhs, rhs, desc = desc }
                end)
                :totable()
        end,
        opts = {
            ---@type snacks.picker.Config
            picker = {
                enabled = true,
                ui_select = true,
                sources = {
                    git_log = {
                        confirm = {
                            'close',
                            function(_, item)
                                vim.fn.setreg(vim.v.register, item.commit)
                                vim.notify(string.format('Commit %s is copied', item.commit), vim.log.levels.INFO, {
                                    title = 'Git Log',
                                })
                            end,
                        },
                    },
                    explorer = {
                        layout = {
                            cycle = false,
                            layout = {
                                width = 30,
                                min_width = 30,
                            },
                        },
                        actions = {
                            sibling_first = sibling_action(actions.first),
                            sibling_last = sibling_action(actions.last),
                            sibling_prev = sibling_action(actions.prev),
                            sibling_next = sibling_action(actions.next),
                            git_diff = function(_, item)
                                git_diff(item.file)
                            end,
                        },
                        win = {
                            list = {
                                keys = {
                                    ['u'] = 'explorer_up',
                                    ['<c-c>'] = 'explorer_copy',
                                    ['R'] = 'explorer_update',
                                    ['c'] = 'explorer_cd',
                                    [']c'] = 'explorer_git_next',
                                    ['[c'] = 'explorer_git_prev',
                                    ['J'] = 'sibling_last',
                                    ['K'] = 'sibling_first',
                                    ['<c-j>'] = 'sibling_next',
                                    ['<c-k>'] = 'sibling_prev',
                                    ['gd'] = 'git_diff',
                                },
                            },
                        },
                    },
                },
            },
        },
    },

    {
        'nvim-telescope/telescope.nvim',
        cmd = { 'Telescope' },
        dependencies = {
            'nvim-lua/popup.nvim',
            'nvim-lua/plenary.nvim',
        },
        opts = {
            defaults = {
                layout_config = {
                    prompt_position = 'top',
                    horizontal = {
                        preview_width = 0.5,
                    },
                },
                sorting_strategy = 'ascending',
                vimgrep_arguments = {
                    'rg',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                    '--smart-case',
                },
                prompt_prefix = ' 󰍉 ',
                selection_caret = ' ',
            },
        },
        config = function(_, opts)
            require('telescope').setup(opts)

            local group_id = vim.api.nvim_create_augroup('dotvim_telescope', { clear = true })
            vim.api.nvim_create_autocmd('User', {
                group = group_id,
                pattern = 'TelescopePreviewerLoaded',
                callback = function()
                    vim.wo.number = true
                end,
            })
        end,
    },
    {
        'nvim-telescope/telescope-file-browser.nvim',
        keys = {
            { '<leader>l', '<cmd>Telescope file_browser<CR>', remap = true, desc = '[Telescope] file browser' },
        },
        dependencies = {
            'nvim-telescope/telescope.nvim',
            opts = {
                extensions = {
                    file_browser = {
                        git_status = true,
                    },
                },
            },
        },
    },
}
