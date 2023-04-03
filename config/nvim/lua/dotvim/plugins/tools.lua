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
        'numToStr/Comment.nvim',
        event = { 'BufNewFile', 'BufReadPost' },
        config = function()
            require('Comment').setup()
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
        event = 'VeryLazy',
        config = function()
            vim.api.nvim_set_keymap('v', '<Leader>vb', ':VBox<CR>', { noremap = true })
        end,
    },

    {
        'rcarriga/nvim-notify',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
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
                            vim.api.nvim_buf_set_option(buf, 'filetype', filetype)
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
        config = function()
            -- you can configure Hop the way you like here; see :h hop-config
            require('hop').setup({ keys = 'etovxqpdygfblzhckisuran' })
            vim.api.nvim_set_keymap('n', '<leader>w', '<cmd>HopWord<CR>', {})
            vim.api.nvim_set_keymap('n', '<leader>l', '<cmd>HopLine<CR>', {})
        end,
    },

    {
        'nathom/filetype.nvim',
        lazy = false,
        config = function()
            require('filetype').setup({
                overrides = {},
            })
        end,
    },

    {
        'max397574/colortils.nvim',
        cmd = 'Colortils',
        config = function()
            require('colortils').setup({})
        end,
    },

    {
        'rest-nvim/rest.nvim',
        dependencies = { 'plenary' },
        ft = 'http',
        config = function(_, opts)
            require('rest-nvim').setup(opts)
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'http',
                group = vim.api.nvim_create_augroup('dotvim_rest', { clear = true }),
                desc = 'run http request',
                callback = function()
                    vim.keymap.set('n', '<leader>r', '<Plug>RestNvim', { desc = 'run http request', buffer = 0 })
                end,
            })
        end,
        opts = {
            -- Open request results in a horizontal split
            result_split_horizontal = false,
            -- Keep the http file buffer above|left when split horizontal|vertical
            result_split_in_place = false,
            -- Skip SSL verification, useful for unknown certificates
            skip_ssl_verification = false,
            -- Encode URL before making request
            encode_url = true,
            -- Highlight request on run
            highlight = {
                enabled = true,
                timeout = 150,
            },
            result = {
                -- toggle showing URL, HTTP info, headers at top the of result window
                show_url = true,
                show_http_info = true,
                show_headers = true,
                -- executables or functions for formatting response body [optional]
                -- set them to false if you want to disable them
                formatters = {
                    json = 'jq',
                    html = function(body)
                        return vim.fn.system({ 'tidy', '-i', '-q', '-' }, body)
                    end,
                },
            },
            -- Jump to request line on run
            jump_to_request = false,
            env_file = '.env',
            custom_dynamic_variables = {},
            yank_dry_run = true,
        },
    },

    {
        'nvim-neotest/neotest',
        dependencies = {
            'plenary',
            'nvim-treesitter/nvim-treesitter',
        },
    },

    {
        'nvim-neotest/neotest-go',
        ft = 'go',
        config = function()
            require('neotest').setup({
                adapters = {
                    require('neotest-go'),
                },
            })
        end,
    },
}
