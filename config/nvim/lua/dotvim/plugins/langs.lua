local vim = vim

return {
    {
        'Vimjas/vim-python-pep8-indent',
        ft = { 'python' },
    },

    {
        'neoclide/jsonc.vim',
        ft = { 'jsonc' },
    },

    {
        'stephpy/vim-yaml',
        ft = { 'yaml' },
    },

    {
        'zdharma-continuum/zinit-vim-syntax',
        ft = { 'zsh' },
    },

    {
        'rust-lang/rust.vim',
        ft = { 'rust', 'rs' },
    },

    {
        'neovimhaskell/haskell-vim',
        ft = { 'haskell', 'hs' },
    },

    {
        'KSP-KOS/EditorTools',
        branch = 'develop',
        ft = 'kerboscript',
        init = function(plugin)
            vim.opt.rtp:append(plugin.dir .. '/VIM/vim-kerboscript')
        end,
    },

    {
        'euclidianAce/BetterLua.vim',
        ft = { 'lua' },
        init = function()
            vim.g.BetterLua_enable_emmylua = 1
        end,
    },

    {
        'milisims/nvim-luaref',
        ft = 'lua',
    },

    {
        'nanotee/luv-vimdocs',
        event = { 'CmdlineEnter' },
    },

    {
        'baskerville/vim-sxhkdrc',
        ft = 'sxhkdrc',
    },

    {
        'tmux-plugins/vim-tmux',
        ft = 'tmux',
    },

    {
        'towolf/vim-helm',
        ft = 'helm',
        config = function()
            local group_id = vim.api.nvim_create_augroup('dotvim_helm', { clear = true })
            vim.api.nvim_create_autocmd({ 'BufReadPre' }, {
                group = group_id,
                pattern = '_helpers.tpl',
                command = 'setlocal nomodeline',
            })
            vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
                group = group_id,
                pattern = '_helpers.tpl',
                command = 'set filetype=helm',
            })
        end,
    },

    {
        'Fymyte/rasi.vim',
        ft = 'rasi',
        dependencies = {
            { 'ap/vim-css-color', ft = 'rasi' },
        },
    },

    {
        'NoahTheDuke/vim-just',
        ft = { 'just' },
    },

    {
        'imsnif/kdl.vim',
        ft = { 'kdl' },
    },

    {
        'Xuyuanp/sqlx-rs.nvim',
        dev = true,
        ft = { 'rust' },
        cmd = { 'SqlxFormat' },
        build = function()
            vim.fn.system({
                'pip',
                'install',
                '-U',
                'sqlparse',
            })
        end,
        config = function()
            local sqlx = require('sqlx')
            sqlx.setup({})

            vim.api.nvim_create_autocmd('BufWritePre', {
                pattern = '*.rs',
                group = vim.api.nvim_create_augroup('sqlx-rs-auto-format', { clear = true }),
                command = 'SqlxFormat',
                desc = '[sqlx-rs] format on save',
            })
        end,
    },
}
