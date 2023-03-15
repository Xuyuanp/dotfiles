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
        event = 'VeryLazy',
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
        'lewis6991/gitsigns.nvim',
        name = 'gitsigns',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'plenary' },
        config = function()
            require('gitsigns').setup({
                signs = {
                    add = { hl = 'GitSignsAdd', text = '┃', numhl = '', linehl = '' },
                    change = { hl = 'GitSignsChange', text = '┃', numhl = '', linehl = '' },
                    delete = { hl = 'GitSignsDelete', text = '┃', numhl = '', linehl = '' },
                    topdelete = { hl = 'GitSignsDelete', text = '┃', numhl = '', linehl = '' },
                    changedelete = { hl = 'GitSignsChange', text = '┃', numhl = '', linehl = '' },
                    untracked = { hl = 'GitSignsAdd', text = '┃', numhl = '', linehl = '' },
                },
                keymaps = {
                    noremap = true,
                    buffer = true,
                    ['n ]c'] = { expr = true, [[&diff ? ']c' : '<cmd>lua require"gitsigns.actions".next_hunk()<CR>']] },
                    ['n [c'] = { expr = true, [[&diff ? '[c' : '<cmd>lua require"gitsigns.actions".prev_hunk()<CR>']] },
                    ['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
                    ['v <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
                    ['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
                    ['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
                    ['v <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
                    ['n <leader>hR'] = '<cmd>lua require"gitsigns".reset_buffer()<CR>',
                    ['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
                    ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line(true)<CR>',
                    -- Text objects
                    ['o ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>',
                    ['x ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>',
                },
                current_line_blame = true,
                current_line_blame_formatter = '@<author> / <abbrev_sha> <summary> / <author_time:%R>',
            })
        end,
    },

    {
        'rcarriga/nvim-notify',
        event = 'VeryLazy',
        config = function()
            vim.notify = require('notify')

            vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
                group = vim.api.nvim_create_augroup('dotvim_notify', { clear = true }),
                pattern = '*',
                callback = function()
                    package.loaded['notify.config.highlights'] = nil
                    require('notify.config.highlights')
                end,
            })
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
        'mhartington/formatter.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local fmt = require('formatter')
            local util = require('formatter.util')
            local python_formaters = require('formatter.filetypes.python')
            fmt.setup({
                logging = true,
                log_level = vim.log.levels.WARN,
                filetype = {
                    lua = require('formatter.filetypes.lua').stylua,
                    python = {
                        python_formaters.black,
                        python_formaters.isort,
                        python_formaters.yapf,
                        python_formaters.autopep8,
                    },
                    go = {
                        function()
                            return {
                                exe = 'goimports-reviser',
                                args = { '-set-alias', '-use-cache', '-rm-unused', '-output=file' },
                            }
                        end,
                    },
                    proto = function()
                        return {
                            exe = 'buf',
                            args = {
                                'format',
                                util.get_current_buffer_file_path(),
                            },
                            stdin = true,
                        }
                    end,
                    graphql = {
                        require('formatter.filetypes.graphql').prettierd,
                    },
                    ['*'] = {
                        require('formatter.filetypes.any').remove_trailing_whitespace,
                    },
                },
            })

            vim.api.nvim_create_autocmd('BufWritePost', {
                group = vim.api.nvim_create_augroup('dotvim_format', { clear = true }),
                pattern = '*',
                command = 'FormatWrite',
            })
        end,
    },

    {
        'rest-nvim/rest.nvim',
        dependencies = { 'plenary' },
        ft = 'http',
        event = 'VeryLazy',
        keys = {
            { '<leader>r', '<Plug>RestNvim', desc = 'run http request' },
        },
        config = function()
            require('rest-nvim').setup({
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
            })
        end,
    },

    {
        'nvim-neotest/neotest',
        dependencies = {
            'plenary',
            'nvim-treesitter/nvim-treesitter',
            'nvim-neotest/neotest-go',
        },
        event = 'VeryLazy',
        config = function()
            require('neotest').setup({
                adapters = {
                    require('neotest-go'),
                },
            })
        end,
    },
}
