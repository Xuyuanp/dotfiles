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
        'neovimhaskell/haskell-vim',
        ft = { 'haskell', 'hs' },
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
            'ap/vim-css-color',
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
        'martinda/Jenkinsfile-vim-syntax',
        ft = 'Jenkinsfile',
    },

    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = { 'markdown' },
        opts = {
            file_types = { 'markdown' },
        },
        opts_extend = { 'file_types' },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        specs = {
            {
                'saghen/blink.cmp',
                optional = true,
                opts = {
                    sources = {
                        providers = {
                            markdown = {
                                name = 'RenderMarkdown',
                                module = 'render-markdown.integ.blink',

                                -- extra
                                filetypes = { 'markdown' },
                            },
                        },
                    },
                },
            },
        },
    },
    {
        'mistweaverco/kulala.nvim',
        ft = 'http',
        init = function()
            vim.filetype.add({
                extension = {
                    http = 'http',
                },
            })
        end,
        opts = {
            winbar = true,
        },
        config = function(_, opts)
            local kulala = require('kulala')
            kulala.setup(opts)

            local a = require('dotvim.util.async')

            local show_menu = a.wrap(function()
                local actions = {
                    'run',
                    'run_all',
                    'replay',
                    'inspect',
                    'show_stats',
                    'copy',
                    'from_curl',
                    'toggle_view',
                    'jump_prev',
                    'jump_next',
                }
                local action = a.ui.select(actions, { prompt = 'Select Action:' }).await()
                if not action then
                    return
                end
                a.schedule().await()
                kulala[action]()
            end)

            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'http',
                callback = function(ev)
                    vim.keymap.set('n', '<A-m>', show_menu, { buffer = ev.buf, remap = true, desc = '[Kulala] menu' })
                end,
            })
        end,
    },
}
