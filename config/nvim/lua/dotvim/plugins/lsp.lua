return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'folke/neoconf.nvim',
            'williamboman/mason-lspconfig.nvim',
            'simrat39/rust-tools.nvim',
            'nvimtools/none-ls.nvim',
            'lvimuser/lsp-inlayhints.nvim',
            'onsails/lspkind-nvim',
            'j-hui/fidget.nvim',
        },
        config = function()
            require('dotvim.config.lsp')
        end,
    },

    {
        'folke/neoconf.nvim',
        cmd = 'Neoconf',
        config = true,
    },

    {
        'simrat39/rust-tools.nvim',
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
            'neovim/nvim-lspconfig',
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
            {
                'saadparwaiz1/cmp_luasnip',
                dependencies = {
                    'L3MON4D3/LuaSnip',
                },
            },
            'andersevenrud/compe-tmux',
            'windwp/nvim-autopairs',
            'onsails/lspkind-nvim',
            {
                {
                    'Exafunction/codeium.nvim',
                    dependencies = {
                        'nvim-lua/plenary.nvim',
                        'hrsh7th/nvim-cmp',
                    },
                    cmd = 'Codeium',
                    config = function()
                        require('codeium').setup({})
                    end,
                },
            },
        },
        config = function()
            require('dotvim.config.complete').setup()
        end,
    },

    {

        'Saecki/crates.nvim',
        dependencies = {
            'hrsh7th/nvim-cmp',
        },
        event = { 'BufReadPre Cargo.toml' },
        config = function()
            require('crates').setup({
                autoload = true,
                null_ls = {
                    enabled = true,
                },
            })
            local cmp = require('cmp')
            cmp.setup.filetype('toml', {
                sources = {
                    { name = 'crates' },
                    { name = 'nvim_lsp' },
                },
            })
        end,
    },

    {
        'L3MON4D3/LuaSnip',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
        keys = {
            {
                '<C-j>',
                function()
                    return require('luasnip').jumpable(1) and '<Plug>luasnip-jump-next' or '<C-j>'
                end,
                expr = true,
                silent = true,
                desc = '[LuaSnip] jump next',
                mode = { 'i', 's' },
            },
            {
                '<C-k>',
                function()
                    return require('luasnip').jumpable(-1) and '<Plug>luasnip-jump-prev' or '<C-k>'
                end,
                expr = true,
                silent = true,
                desc = '[LuaSnip] jump prev',
                mode = { 'i', 's' },
            },
        },
        config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
            require('luasnip.loaders.from_vscode').lazy_load({ paths = { './snippets' } })

            local luasnip = require('luasnip')
            luasnip.setup({
                history = true,
                delete_check_events = 'TextChanged',
            })
        end,
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
                        { name = 'luasnip' },
                    }),
                })
            end
        end,
    },

    {
        'onsails/lspkind-nvim',
        config = function()
            require('lspkind').init({
                mode = 'symbol_text',
                -- default symbol map
                -- can be either 'default' or
                -- 'codicons' for codicon preset (requires vscode-codicons font installed)
                --
                -- default: 'default'
                preset = 'default',
                symbol_map = {
                    Codeium = '󱃖',
                },
            })
        end,
    },

    {
        'nvimtools/none-ls.nvim',
        config = function()
            require('dotvim.config.lsp.null').setup()
        end,
    },

    {
        'j-hui/fidget.nvim',
        tag = 'legacy',
        opts = {
            text = {
                spinner = 'meter',
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
    },
}
