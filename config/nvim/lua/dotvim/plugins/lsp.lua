return {
    {
        'neovim/nvim-lspconfig',
        lazy = false,
        dependencies = {
            'folke/neoconf.nvim',
        },
        config = false,
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
    { 'Bilal2453/luvit-meta' }, -- optional `vim.uv` typings

    {
        'williamboman/mason.nvim',
        version = 'v2',
        lazy = false,
        opts = {
            PATH = 'append',
            ui = {
                border = 'rounded',
            },
        },
        config = function(_, opts)
            require('mason').setup(opts)

            local disabled = { 'rust_analyzer', 'stylua' }

            for _, pkg in ipairs(require('mason-registry').get_installed_packages()) do
                local ls_name = vim.tbl_get(pkg, 'spec', 'neovim', 'lspconfig')
                if ls_name and not vim.tbl_contains(disabled, ls_name) then
                    vim.lsp.enable(ls_name)
                end
            end
        end,
    },

    {
        'nvimtools/none-ls.nvim',
        event = 'VeryLazy',
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
            backend = { 'snacks' },
            snacks = {
                layout = {
                    -- copy from preset layout 'vertical'
                    layout = {
                        backdrop = false,
                        width = 0.5,
                        min_width = 80,
                        height = 0.8,
                        min_height = 30,
                        box = 'vertical',
                        border = 'rounded',
                        title = '{title} {live} {flags}',
                        title_pos = 'center',
                        { win = 'input', height = 1, border = 'bottom' },
                        { win = 'list', border = 'none' },
                        { win = 'preview', title = '{preview}', height = 0.8, border = 'top' },
                    },
                },
            },
        },
    },

    {
        'mrcjkb/rustaceanvim',
        version = '^6',
        dependencies = {
            {
                'jay-babu/mason-nvim-dap.nvim',
                optional = true,
                opts = {
                    automatic_setup = {
                        filetypes = {
                            rust = false,
                        },
                    },
                },
            },
        },
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
