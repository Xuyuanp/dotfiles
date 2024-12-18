return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'folke/neoconf.nvim',
            'williamboman/mason-lspconfig.nvim',
            'nvimtools/none-ls.nvim',
            'junegunn/fzf.vim',
        },
        config = function()
            require('dotvim.config.lsp').setup()
        end,
    },

    {
        'folke/neoconf.nvim',
        cmd = 'Neoconf',
        opts = {},
    },

    {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = 'luvit-meta/library', words = { 'vim%.uv' } },
            },
        },
    },
    { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings

    {
        'williamboman/mason.nvim',
        cmd = 'Mason',
        opts = {
            PATH = 'append',
        },
    },

    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = {
            'williamboman/mason.nvim',
        },
        opts = {},
    },

    {
        'jay-babu/mason-null-ls.nvim',
        dependencies = {
            'williamboman/mason.nvim',
        },
        opts = {
            automatic_installation = true,
            ensure_installed = {},
        },
    },

    {
        'nvimtools/none-ls.nvim',
        dependencies = {
            'jay-babu/mason-null-ls.nvim',
        },
        config = function()
            require('dotvim.config.lsp.null').setup()
        end,
    },

    {
        'Saecki/crates.nvim',
        event = { 'BufRead Cargo.toml' },
        opts = {
            autoload = true,
            lsp = {
                enabled = true,
                completion = true,
                actions = true,
                hover = true,
            },
        },
    },

    {
        'j-hui/fidget.nvim',
        version = '*',
        event = 'LspAttach',
        opts = {
            progress = {
                display = {
                    progress_icon = {
                        pattern = 'meter',
                    },
                },
            },
            notification = {
                window = {
                    winblend = vim.o.winblend,
                    border = 'rounded',
                },
            },
        },
    },

    {
        'aznhe21/actions-preview.nvim',
        keys = {
            {
                'gap',
                require('dotvim.util').lazy_require('actions-preview').code_actions,
                mode = { 'n', 'v' },
                desc = '[Lsp] actions preview',
            },
        },
        opts = {
            telescope = {
                sorting_strategy = 'ascending',
                layout_strategy = 'vertical',
                layout_config = {
                    width = 0.8,
                    height = 0.9,
                    prompt_position = 'top',
                    preview_cutoff = 20,
                    preview_height = function(_, _, max_lines)
                        return max_lines - 15
                    end,
                },
            },
        },
    },

    {
        'mrcjkb/rustaceanvim',
        version = '*',
        ft = 'rust',
        config = function()
            require('dotvim.config.lsp.rust').setup()
        end,
    },

    {
        'maxandron/goplements.nvim',
        ft = 'go',
        opts = {},
    },
}
