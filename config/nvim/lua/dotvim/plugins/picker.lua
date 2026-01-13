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
                { key = 'b', source = 'buffers' },
                { key = 'c', source = 'commands' },
                { key = 'e', source = 'explorer' },
                { key = 'f', source = 'files' },
                { key = 'h', source = 'help' },
                { key = 'j', source = 'jumps' },
                { key = 'k', source = 'keymaps' },
                { key = 'l', source = 'lines' },
                { key = 'n', source = 'notifications' },
                { key = 'p', source = 'pickers' },
                { key = 'r', source = 'resume' },
                { key = 's', source = 'grep', desc = 'search' },
                { key = 'glf', source = 'git_log_file' },
            }
            return vim.iter(keys)
                :map(function(k)
                    local lhs = prefix .. k.key
                    local rhs = function()
                        require('snacks.picker').pick(k.source)
                    end
                    local desc = string.gsub(k.desc or k.source, '^%l', string.upper)
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
                    notifications = {
                        win = {
                            preview = {
                                wo = { wrap = true },
                            },
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
                        actions = require('dotvim.config.picker.explorer').actions,
                        win = {
                            list = {
                                keys = {
                                    -- override default explorer actions
                                    ['u'] = 'explorer_up',
                                    ['<c-c>'] = 'explorer_copy',
                                    ['R'] = 'explorer_update',
                                    ['c'] = 'explorer_cd',
                                    [']c'] = 'explorer_git_next',
                                    ['[c'] = 'explorer_git_prev',

                                    -- custom actions
                                    ['H'] = 'sibling_first',
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
}
