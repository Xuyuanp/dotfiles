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
        'rcarriga/nvim-notify',
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.notify = function(...)
                local notify = require('notify')
                ---@diagnostic disable-next-line: duplicate-set-field
                vim.notify = function(msg, level, opts)
                    opts = opts or {}
                    local filetype = opts.filetype
                    if filetype then
                        opts.filetype = nil
                        opts.on_open = require('dotvim.util').wrap_func_after(opts.on_open, function(win)
                            local buf = vim.api.nvim_win_get_buf(win)
                            vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
                        end)
                    end
                    notify(msg, level, opts)
                end

                vim.notify(...)
            end
        end,
    },

    {
        'phaazon/hop.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        branch = 'v1', -- optional but strongly recommended
        opts = {
            keys = 'etovxqpdygfblzhckisuran',
        },
        keys = {
            { '<leader>w', require('dotvim.util').lazy_require('hop').hint_words, mode = 'n', desc = '[Hop] hint words' },
        },
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
        event = 'VeryLazy',
        config = function()
            require('im_select').setup({})
        end,
    },
}
