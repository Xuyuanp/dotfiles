return {
    {
        'jackMort/ChatGPT.nvim',
        cmd = 'ChatGPT',
        config = function()
            require('chatgpt').setup({
                -- optional configuration
            })
        end,
        dependencies = {
            'MunifTanjim/nui.nvim',
            'plenary',
            'telescope',
        },
    },

    {
        'Xuyuanp/neochat.nvim',
        dev = vim.fn.exists('~/workspace/neovim/neochat.nvim'),
        build = function()
            vim.fn.system({
                'pip',
                'install',
                '-U',
                'openai',
            })
        end,
        keys = {
            {
                '<A-g>',
                require('dotvim.util').lazy_require('neochat').toggle,
                mode = { 'n', 'i' },
                desc = 'toggle neochat',
                noremap = false,
            },
        },
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        config = function()
            require('neochat').setup({})
        end,
    },
}
