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
        },
        config = function()
            require('neorg').setup({
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
            })
        end,
    },
}
