local features = require('dotvim.features')

return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'folke/neoconf.nvim',
            'williamboman/mason-lspconfig.nvim',
            'nvimtools/none-ls.nvim',
            'onsails/lspkind-nvim',
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
        lazy = false,
        config = function()
            require('mason').setup({
                PATH = 'append',
            })
        end,
    },

    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = {
            'williamboman/mason.nvim',
        },
        config = function()
            require('mason-lspconfig').setup({})
        end,
    },

    {
        'jay-babu/mason-null-ls.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            'williamboman/mason.nvim',
            'nvimtools/none-ls.nvim',
        },
        config = function()
            require('mason-null-ls').setup({
                automatic_installation = true,
                ensure_installed = {},
            })
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        event = { 'InsertEnter' },
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-calc',
            'garymjr/nvim-snippets',
            'windwp/nvim-autopairs',
            'onsails/lspkind-nvim',
            { 'Exafunction/codeium.nvim', optional = true },
            { 'zbirenbaum/copilot-cmp', optional = true },
            { 'andersevenrud/compe-tmux', cond = not not vim.env.TMUX },
        },
        config = function()
            require('dotvim.config.complete').setup()
        end,
    },

    {
        'zbirenbaum/copilot-cmp',
        cond = features.copilot,
        dependencies = {
            'zbirenbaum/copilot.lua',
        },
        opts = {},
    },
    {
        'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        opts = {},
    },

    {
        'Exafunction/codeium.nvim',
        cond = features.codeium,
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        cmd = 'Codeium',
        opts = {},
    },

    {
        'Saecki/crates.nvim',
        event = { 'BufRead Cargo.toml' },
        opts = {
            autoload = true,
            null_ls = {
                enabled = true,
            },
            lsp = {
                enabled = true,
                completion = true,
                actions = true,
                hover = true,
            },
        },
    },

    {
        'garymjr/nvim-snippets',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
        opts = {
            friendly_snippets = true,
            search_paths = { './snippets' },
        },
    },

    {
        'petertriho/cmp-git',
        ft = { 'gitcommit' },
        config = function()
            local cmp = require('cmp')
            local cmp_git = require('cmp_git')
            if cmp_git then
                cmp_git.setup()
                cmp.setup.filetype('gitcommit', {
                    sources = cmp.config.sources({
                        { name = 'git' },
                    }, {
                        { name = 'buffer' },
                        { name = 'snippets' },
                    }),
                })
            end
        end,
    },

    {
        'onsails/lspkind-nvim',
        opts = {
            mode = 'symbol_text',
            -- default symbol map
            -- can be either 'default' or
            -- 'codicons' for codicon preset (requires vscode-codicons font installed)
            --
            -- default: 'default'
            preset = 'default',
            symbol_map = {
                Codeium = '󱃖',
                Copilot = '',
                -- crates.nvim
                Feature = '󰩉',
                Version = '',
            },
        },
    },

    {
        'nvimtools/none-ls.nvim',
        config = function()
            require('dotvim.config.lsp.null').setup()
        end,
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
