return {
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'folke/neoconf.nvim',
            'williamboman/mason-lspconfig.nvim',
            'folke/neodev.nvim',
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
        'folke/neodev.nvim',
        opts = {
            library = {
                enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
                -- these settings will be used for your Neovim config directory
                runtime = true, -- runtime path
                types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
                plugins = {
                    'nvim-dap-ui',
                }, -- installed opt or start plugins in packpath
                -- you can also specify the list of plugins to make available as a workspace library
                -- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
            },
            setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
            -- for your Neovim config directory, the config.library settings will be used as is
            -- for plugin directories (root_dirs having a /lua directory), config.library.plugins will be disabled
            -- for any other directory, config.library.enabled will be set to false
            -- override = function(root_dir, options) end,
            -- With lspconfig, Neodev will automatically setup your lua-language-server
            -- If you disable this, then you have to set {before_init=require("neodev.lsp").before_init}
            -- in your lsp start options
            lspconfig = true,
            -- much faster, but needs a recent built of lua-language-server
            -- needs lua-language-server >= 3.6.0
            pathStrict = true,
        },
    },

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
            'zbirenbaum/copilot-cmp',
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
                    { name = 'copilot' },
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
                    Copilot = '',
                    Codeium = '󱃖',
                },
            })
        end,
    },

    {
        'lvimuser/lsp-inlayhints.nvim',
        cond = function()
            return vim.fn.has('nvim-0.10') == 0
        end,
        config = function()
            local inlayhints = require('lsp-inlayhints')
            inlayhints.setup({
                inlay_hints = {
                    parameter_hints = {
                        show = true,
                        prefix = '<- ',
                        separator = ', ',
                        remove_colon_start = false,
                        remove_colon_end = true,
                    },
                    type_hints = {
                        -- type and other hints
                        show = true,
                        prefix = '=> ',
                        separator = ', ',
                        remove_colon_start = false,
                        remove_colon_end = false,
                    },
                    only_current_line = false,
                    -- separator between types and parameter hints. Note that type hints are
                    -- shown before parameter
                    labels_separator = '  ',
                    -- whether to align to the length of the longest line in the file
                    max_len_align = false,
                    -- padding from the left if max_len_align is true
                    max_len_align_padding = 1,
                    -- highlight group
                    highlight = 'Comment',
                    -- virt_text priority
                    priority = 0,
                },
                enabled_at_startup = true,
                debug_mode = false,
            })

            require('dotvim.util').on_lsp_attach(function(client, bufnr)
                if client.name == 'rust_analyzer' then
                    return
                end
                inlayhints.on_attach(client, bufnr, false)
            end, { desc = 'setup inlay hints' })
        end,
    },

    {
        'nvimtools/none-ls.nvim',
        config = function()
            require('dotvim.config.lsp.null').setup()
        end,
    },

    {

        'zbirenbaum/copilot.lua',
        cmd = { 'Copilot' },
        opts = {
            suggestion = { enabled = false },
            panel = { enabled = false },
        },
    },

    {
        'zbirenbaum/copilot-cmp',
        dependencies = {
            'zbirenbaum/copilot.lua',
        },
        config = function()
            require('copilot_cmp').setup()
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
