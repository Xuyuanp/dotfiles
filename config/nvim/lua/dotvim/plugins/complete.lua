local features = require('dotvim.features')

return {
    {
        'hrsh7th/nvim-cmp',
        event = { 'InsertEnter' },
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lsp-signature-help',
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
}
