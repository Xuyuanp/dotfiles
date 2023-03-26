return {
    {
        'nvim-neorg/neorg',
        cmd = { 'Neorg' },
        ft = { 'norg' },
        dependencies = {
            'plenary',
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
                    ['core.norg.concealer'] = {}, -- Adds pretty icons to your documents
                    ['core.norg.completion'] = {
                        config = {
                            engine = 'nvim-cmp',
                        },
                    },
                    ['core.norg.dirman'] = { -- Manages Neorg workspaces
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
        build = ':Neorg sync-parsers',
    },
}
