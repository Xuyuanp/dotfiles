local vim = vim

return {
    {
        'vim-scripts/a.vim',
        ft = { 'c', 'cpp' },
    },

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
        'plasticboy/vim-markdown',
        ft = { 'markdown', 'md' },
        init = function()
            vim.g.vim_markdown_folding_disabled = 1
        end,
    },

    {
        'rust-lang/rust.vim',
        ft = { 'rust', 'rs' },
    },

    {
        'simrat39/rust-tools.nvim',
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

    'milisims/nvim-luaref',
    'nanotee/luv-vimdocs',

    {
        'mfussenegger/nvim-dap',
        name = 'dap',
        dependencies = { 'plenary' },
        config = function()
            require('dotvim.dap').setup()
        end,
    },

    {
        'rcarriga/nvim-dap-ui',
        dependencies = 'dap',
        config = function()
            require('dotvim.dap').ui.setup()
        end,
    },

    {
        'theHamsta/nvim-dap-virtual-text',
        dependencies = {
            'dap',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('dotvim.dap').virtual_text.setup()
        end,
    },

    {
        'mfussenegger/nvim-dap-python',
        dependencies = { 'dap' },
        config = function()
            local dap_py = require('dap-python')
            dap_py.setup('~/.pyenv/versions/debugpy/bin/python')
            dap_py.test_runner = 'pytest'
        end,
    },

    {
        'nvim-telescope/telescope-dap.nvim',
        dependencies = { 'dap', 'telescope' },
        config = function()
            require('telescope').load_extension('dap')
        end,
    },

    {
        'baskerville/vim-sxhkdrc',
        ft = 'sxhkdrc',
    },

    {
        'towolf/vim-helm',
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
        'jparise/vim-graphql',
        ft = { 'graphql' },
    },
}
