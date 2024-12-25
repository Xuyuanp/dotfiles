local features = require('dotvim.features')

local M = {
    {
        'hrsh7th/nvim-cmp',
        event = { 'InsertEnter' },
        cond = not features.blink,
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
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.g.dotvim_lsp_capabilities = function()
                return require('cmp_nvim_lsp').default_capabilities()
            end
        end,
        config = function()
            require('dotvim.config.coding.cmp').setup()
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
        cond = not features.blink,
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

return M
