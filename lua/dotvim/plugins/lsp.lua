return {
    {
        'williamboman/nvim-lsp-installer',
        as = 'lsp-installer',
    },
    {
        'neovim/nvim-lspconfig',
        requires = {
            'lsp-installer',
        },
        as = 'lspconfig',
        config = function()
            require('dotvim/lsp')
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
                    border = 'single',
                },
            })
        end,
    },

    {
        'nvim-lua/lsp_extensions.nvim',
        requires = { 'lspconfig' },
        config = function()
            local command = vim.api.nvim_command
            _G.lsp_inlay_hints = function()
                return require('lsp_extensions').inlay_hints({
                    prefix = ' » ',
                    highlight = 'NonText',
                    enabled = {
                        'TypeHint',
                        'ParameterHint',
                        'ChainingHint',
                    },
                })
            end
            command([[augroup dotvim_lsp_extensions]])
            command([[autocmd!]])
            command([[autocmd InsertLeave,BufEnter,BufWinEnter,TabEnter,BufWritePost *.rs lua lsp_inlay_hints()]])
            command([[augroup END]])
        end,
    },

    {
        'nvim-lua/lsp-status.nvim',
        before = {
            'lsp-installer',
        },
    },

    {
        'hrsh7th/vim-vsnip',
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
        requires = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lua',
            'hrsh7th/cmp-nvim-lsp',
            {
                'andersevenrud/compe-tmux',
                branch = 'cmp',
            },
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-calc',
            'hrsh7th/cmp-vsnip',
            'Saecki/crates.nvim',
        },
        config = function()
            require('dotvim.complete').setup()
        end,
    },

    {
        'onsails/lspkind-nvim',
        config = function()
            require('lspkind').init({
                -- enables text annotations
                --
                -- default: true
                with_text = true,

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
}
