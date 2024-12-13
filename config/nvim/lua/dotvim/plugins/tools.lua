return {
    {
        'tpope/vim-surround',
        event = { 'BufReadPost', 'BufNewFile' },
    },
    {
        'mg979/vim-visual-multi',
        event = { 'BufReadPost', 'BufNewFile' },
    },

    {
        'windwp/nvim-autopairs',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local npairs = require('nvim-autopairs')
            npairs.setup()

            local Rule = require('nvim-autopairs.rule')
            npairs.add_rules({
                Rule(' ', ' '):with_pair(function(opts)
                    local pair = opts.line:sub(opts.col - 1, opts.col)
                    return vim.tbl_contains({ '()', '[]', '{}', '<>' }, pair)
                end),
                Rule('( ', ' )')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%)') ~= nil
                    end)
                    :use_key(')'),
                Rule('{ ', ' }')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%}') ~= nil
                    end)
                    :use_key('}'),
                Rule('[ ', ' ]')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%]') ~= nil
                    end)
                    :use_key(']'),
                Rule('< ', ' >')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%>') ~= nil
                    end)
                    :use_key('>'),
            })
        end,
    },

    {
        'junegunn/vim-easy-align',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local set_keymap = vim.keymap.set
            set_keymap('v', '<CR><Space>', ':EasyAlign\\<CR>', { noremap = true })
            set_keymap('v', '<CR>2<Space>', ':EasyAlign2\\<CR>', { noremap = true })
            set_keymap('v', '<CR>-<Space>', ':EasyAlign-\\<CR>', { noremap = true })
            set_keymap('v', '<CR>-2<Space>', ':EasyAlign-2\\<CR>', { noremap = true })
            set_keymap('v', '<CR>:', ':EasyAlign:<CR>', { noremap = true })
            set_keymap('v', '<CR>=', ':EasyAlign=<CR>', { noremap = true })
            set_keymap('v', '<CR><CR>=', ':EasyAlign!=<CR>', { noremap = true })
            set_keymap('v', '<CR>"', ':EasyAlign"<CR>', { noremap = true })
        end,
    },

    {
        'dstein64/vim-startuptime',
        cmd = 'StartupTime',
    },

    {
        'voldikss/vim-translator',
        cmd = {
            'Translate',
            'TranslateH',
            'TranslateL',
            'TranslateR',
            'TranslateW',
            'TranslateX',
        },
        init = function()
            vim.g.translator_history_enable = true
        end,
    },

    {
        'matze/vim-move',
        event = { 'BufNewFile', 'BufReadPost' },
    },

    {
        'jbyuki/venn.nvim',
        keys = {
            { '<Leader>vb', ':<C-e>VBox<CR>', mode = 'v', desc = '[Venn] draw vbox' },
        },
    },

    {
        'folke/snacks.nvim',
        lazy = false,
        priority = 1000,
        init = function()
            local subcommands = {
                notifications = function()
                    require('snacks.notifier').show_history()
                end,
            }

            ---@type vim.api.keyset.user_command
            local cmdopts = {
                force = true,
                nargs = 1,
                complete = function(lead)
                    return vim.tbl_filter(function(cmd)
                        return vim.startswith(cmd, lead)
                    end, vim.tbl_keys(subcommands))
                end,
            }

            local function command(ev)
                local action = subcommands[ev.args]
                if not action then
                    vim.notify('Unknown subcommand: ' .. ev.args, vim.log.levels.ERROR, {
                        title = 'Snacks',
                    })
                    return
                end
                action(ev)
            end

            vim.api.nvim_create_user_command('Snacks', command, cmdopts)
        end,
        opts = {
            bigfile = { enabled = true },
            quickfile = { enabled = true },
            notifier = { enabled = true },
            indent = {},
        },
    },

    {
        'folke/flash.nvim',
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash',
            },
            {
                'S',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').treesitter()
                end,
                desc = 'Flash Treesitter',
            },
            {
                '<C-s>',
                mode = { 'c' },
                function()
                    require('flash').toggle()
                end,
                desc = 'Toggle Flash Search',
            },
        },
        opts = {},
    },

    {
        'max397574/colortils.nvim',
        cmd = 'Colortils',
        config = function()
            require('colortils').setup({})
        end,
    },

    {
        'keaising/im-select.nvim',
        cond = vim.fn.has('mac') == 1,
        event = 'InsertEnter',
        config = function()
            require('im_select').setup({})
        end,
    },
}
