return {
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
