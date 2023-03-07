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
        dependencies = {
            'tamago324/nlsp-settings.nvim',
        },
        name = 'lspconfig',
        config = function()
            require('dotvim.lsp')
        end,
    },
    {
        'williamboman/mason.nvim',
        dependencies = {
            'lspconfig',
            'williamboman/mason-lspconfig.nvim',
        },
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
        'hrsh7th/vim-vsnip',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
        config = function()
            local vim = vim
            local vfn = vim.fn
            local command = vim.api.nvim_command

            vim.g.vsnip_snippet_dir = vfn.stdpath('config') .. '/snippets'
            command([[ imap <expr> <C-j> vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>' ]])
            command([[ smap <expr> <C-j> vsnip#available(1)  ? '<Plug>(vsnip-jump-next)' : '<C-j>' ]])
            command([[ imap <expr> <C-k> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>' ]])
            command([[ smap <expr> <C-k> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)' : '<C-k>' ]])
        end,
    },

    {
        'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lua',
            'hrsh7th/cmp-nvim-lsp',
            'andersevenrud/compe-tmux',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-calc',
            'hrsh7th/cmp-vsnip',
            'hrsh7th/cmp-cmdline',
            'Saecki/crates.nvim',
            'petertriho/cmp-git',
        },
        config = function()
            require('dotvim.complete').setup()
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
        'mfussenegger/nvim-lint',
        config = function()
            local lint = require('lint')
            -- lint.linters_by_ft.lua = { 'luacheck' }
            lint.linters_by_ft.vim = { 'vint' }
            -- lint.linters_by_ft.python = { 'pylint', 'flake8' }
            local codespell = vim.tbl_deep_extend('force', lint.linters.codespell, {
                args = { '--config', vim.env.HOME .. '/.config/codespell/config.toml' },
                name = 'codespell',
            })

            local group_id = vim.api.nvim_create_augroup('dotvim_lint', { clear = true })
            vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufWritePost' }, {
                group = group_id,
                pattern = '*',
                callback = function()
                    lint.try_lint()
                    lint.lint(codespell)
                end,
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

            local group_id = vim.api.nvim_create_augroup('LspAttach_inlayhints', { clear = true })
            vim.api.nvim_create_autocmd('LspAttach', {
                group = group_id,
                callback = function(args)
                    if not (args.data and args.data.client_id) then
                        return
                    end

                    local bufnr = args.buf
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    if client.name == 'rust_analyzer' then
                        return
                    end
                    inlayhints.on_attach(client, bufnr, false)
                end,
            })
        end,
    },
}
