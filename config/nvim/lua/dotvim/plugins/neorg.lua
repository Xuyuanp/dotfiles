return {
    {
        'vhyrro/luarocks.nvim',
        priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
        config = true,
    },
    {
        'nvim-neorg/neorg',
        cmd = { 'Neorg' },
        ft = { 'norg' },
        dependencies = {
            'vhyrro/luarocks.nvim',
            'benlubas/neorg-interim-ls',
        },
        opts = {
            load = {
                ['core.defaults'] = {}, -- Loads default behaviour
                ['core.keybinds'] = {
                    config = {
                        hook = function(keybinds)
                            keybinds.remap_event('norg', 'n', '<leader>mcb', 'core.looking-glass.magnify-code-block')
                        end,
                    },
                },
                ['core.concealer'] = {}, -- Adds pretty icons to your documents
                ['core.dirman'] = { -- Manages Neorg workspaces
                    config = {
                        workspaces = {
                            notes = '~/notes',
                        },
                    },
                },
            },
        },
    },

    {
        'nvim-neorg/neorg',
        optional = true,
        dependencies = {
            'benlubas/neorg-interim-ls',
        },
        opts = {
            load = {
                ['core.completion'] = {
                    config = { engine = { module_name = 'external.lsp-completion' } },
                },
                ['external.interim-ls'] = {
                    config = {
                        completion_provider = {
                            enable = true,
                            documentation = true,
                            -- Try to complete categories provided by Neorg Query. Requires `benlubas/neorg-query`
                            categories = false,
                        },
                    },
                },
            },
        },
    },
}
