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
            'hrsh7th/nvim-cmp',
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
                    ['core.completion'] = {
                        config = {
                            engine = 'nvim-cmp',
                        },
                    },
                    ['core.dirman'] = { -- Manages Neorg workspaces
                        config = {
                            workspaces = {
                                notes = '~/notes',
                            },
                        },
                    },
                },
            })

            local cmp = require('cmp')
            cmp.setup.filetype('norg', {
                sources = cmp.config.sources({
                    { name = 'neorg' },
                }, {
                    { name = 'buffer' },
                }),
            })
        end,
    },
}
