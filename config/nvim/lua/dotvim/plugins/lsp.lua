return {
    {
        'j-hui/fidget.nvim',
        config = function()
            require('fidget').setup({
                text = {
                    spinner = 'meter',
                },
            })
        end,
    },
    {
        'neovim/nvim-lspconfig',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'tamago324/nlsp-settings.nvim',
            'williamboman/mason-lspconfig.nvim',
            'folke/neodev.nvim',
            'simrat39/rust-tools.nvim',
            'jose-elias-alvarez/null-ls.nvim',
            'j-hui/fidget.nvim',
            'ray-x/lsp_signature.nvim',
            'lvimuser/lsp-inlayhints.nvim',
            'onsails/lspkind-nvim',
        },
        name = 'lspconfig',
        config = function()
            require('dotvim.config.lsp')
        end,
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
                plugins = true, -- installed opt or start plugins in packpath
                -- you can also specify the list of plugins to make available as a workspace library
                -- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
            },
            setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
            -- for your Neovim config directory, the config.library settings will be used as is
            -- for plugin directories (root_dirs having a /lua directory), config.library.plugins will be disabled
            -- for any other directory, config.library.enabled will be set to false
            override = function(root_dir, options) end,
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
            require('mason').setup({})
        end,
    },

    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = {
            'lspconfig',
            'williamboman/mason.nvim',
        },
        config = function()
            require('mason-lspconfig').setup({})
        end,
    },

    {
        'ray-x/lsp_signature.nvim',
        config = function()
            require('lsp_signature').setup({
                bind = true,
                floating_window = true,
                floating_window_above_cur_line = true,
                hi_parameter = 'Underlined',
                hint_enable = false,
                use_lspsaga = false,
                handler_opts = {
                    border = 'rounded',
                },
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
                'hrsh7th/cmp-vsnip',
                dependencies = {
                    'hrsh7th/vim-vsnip',
                },
            },
            'andersevenrud/compe-tmux',
            'Saecki/crates.nvim',
            'windwp/nvim-autopairs',
        },
        config = function()
            require('dotvim.config.complete').setup()
        end,
    },

    {
        'hrsh7th/vim-vsnip',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
        config = function()
            local vim = vim
            local vfn = vim.fn

            vim.g.vsnip_snippet_dir = vfn.stdpath('config') .. '/snippets'
            vim.cmd([[imap <expr> <C-j> vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>']])
            vim.cmd([[smap <expr> <C-j> vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>']])
            vim.cmd([[imap <expr> <C-k> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>']])
            vim.cmd([[smap <expr> <C-k> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>']])
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
                        { name = 'vsnip' },
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
                -- override preset symbols
                --
                -- default: {}
                -- symbol_map = {
                --     Text = '',
                --     Method = 'ƒ',
                --     Function = '',
                --     Constructor = '',
                --     Variable = '',
                --     Class = '',
                --     Interface = 'ﰮ',
                --     Module = '',
                --     Property = '',
                --     Unit = '',
                --     Value = '',
                --     Enum = '',
                --     Keyword = '',
                --     Snippet = '﬌',
                --     Color = '',
                --     File = '',
                --     Folder = '',
                --     EnumMember = '',
                --     Constant = '',
                --     Struct = ''
                -- },
                symbol_map = {
                    Text = '',
                    Method = '',
                    Function = 'ƒ',
                    Constructor = '',
                    Variable = '',
                    Class = '',
                    Interface = '',
                    Module = '',
                    Property = '',
                    Unit = '',
                    Value = '',
                    Enum = '',
                    Keyword = '',
                    Snippet = '',
                    Color = '',
                    File = '',
                    Folder = '',
                    EnumMember = '',
                    Constant = '',
                    Operator = 'Ψ',
                    Reference = '渚',
                    Struct = 'פּ',
                    Field = '料',
                    Event = '鬒',
                    TypeParameter = '',
                    Default = '',
                },
            })
        end,
    },

    {
        'lvimuser/lsp-inlayhints.nvim',
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
        'jose-elias-alvarez/null-ls.nvim',
        config = function()
            require('dotvim.config.lsp.null').setup()
        end,
    },
}
