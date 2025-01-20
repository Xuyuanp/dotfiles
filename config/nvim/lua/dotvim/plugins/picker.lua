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
            picker = {
                enabled = true,
                ui_select = true,
                sources = {
                    git_log = {
                        confirm = function(picker, item)
                            picker:close()
                            vim.fn.setreg(vim.v.register, item.commit)
                            vim.notify(string.format('Commit %s is copied', item.commit), vim.log.levels.INFO, {
                                title = 'Git Log',
                            })
                        end,
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
