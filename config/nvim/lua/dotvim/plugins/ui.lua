local vim = vim

return {
    {
        'nvim-telescope/telescope.nvim',
        name = 'telescope',
        version = '*',
        cmd = { 'Telescope' },
        dependencies = {
            'popup',
            'plenary',
        },
        config = function()
            local ts = require('telescope')
            ts.setup({
                defaults = {
                    vimgrep_arguments = {
                        'rg',
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                        '--smart-case',
                    },
                    prompt_prefix = '  ',
                },
            })
        end,
    },

    {
        'Xuyuanp/yanil',
        cmd = { 'YanilToggle', 'Yanil' },
        config = function()
            require('dotvim.config.yanil').setup()

            vim.keymap.set('n', '<C-e>', ':YanilToggle<CR>', { silent = true, noremap = false })

            local group_id = vim.api.nvim_create_augroup('dotvim_yanil', { clear = true })
            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                group = group_id,
                desc = 'Auto quit yanil',
                pattern = { 'Yanil' },
                command = 'if len(nvim_list_wins()) ==1 | q | endif',
            })
            vim.api.nvim_create_autocmd({ 'FocusGained' }, {
                group = group_id,
                desc = 'Auto refresh git status of yanil',
                pattern = { '*' },
                callback = function()
                    require('yanil/git').update()
                end,
            })
        end,
    },

    {
        'mhinz/vim-startify',
        event = 'BufEnter',
        dependencies = {
            -- 'kyazdani42/nvim-web-devicons'
        },
        config = function()
            local vfn = vim.fn
            local command = vim.api.nvim_command

            _G.devicons_get_icon = function(path)
                local filename = vfn.fnamemodify(path, ':t')
                local extension = vfn.fnamemodify(path, ':e')
                return require('nvim-web-devicons').get_icon(filename, extension, { default = true })
            end

            command([[
            function! StartifyEntryFormat()
                return 'v:lua.devicons_get_icon(absolute_path) ." ". entry_path'
            endfunction
            ]])
        end,
    },

    {
        'liuchengxu/vista.vim',
        cmd = 'Vista',
        config = function()
            vim.g.vista_default_executive = 'nvim_lsp'
            vim.api.nvim_set_keymap('n', '<C-t>', ':Vista!!<CR>', { noremap = true })
        end,
    },

    {
        'norcalli/nvim-colorizer.lua',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            require('colorizer').setup()
        end,
    },

    {
        'Xuyuanp/scrollbar.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            vim.g.scrollbar_excluded_filetypes = {
                'nerdtree',
                'vista_kind',
                'Yanil',
            }
            vim.g.scrollbar_highlight = {
                head = 'String',
                body = 'String',
                tail = 'String',
            }
            vim.g.scrollbar_shape = {
                head = '⍋',
                tail = '⍒',
            }

            local group_id = vim.api.nvim_create_augroup('dotvim_scrollbar', { clear = true })

            vim.api.nvim_create_autocmd({ 'BufEnter', 'WinScrolled', 'VimResized' }, {
                group = group_id,
                desc = 'Show or refresh scrollbar',
                pattern = { '*' },
                callback = function()
                    require('scrollbar').show()
                end,
            })
            vim.api.nvim_create_autocmd({ 'BufLeave' }, {
                group = group_id,
                desc = 'Clear scrollbar',
                pattern = { '*' },
                callback = function()
                    require('scrollbar').clear()
                end,
            })
        end,
    },

    {
        'akinsho/bufferline.nvim',
        tag = 'v2.9.1',
        -- dependencies = 'kyazdani42/nvim-web-devicons',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local bufferline = require('bufferline')
            bufferline.setup({
                options = {
                    themable = true,
                    numbers = function(opts)
                        return string.format('%s', opts.raise(opts.ordinal))
                    end,
                    diagnostics = 'nvim_lsp',
                    show_buffer_icons = true,
                    separator_style = 'slant',
                    always_show_bufferline = true,
                    show_buffer_close_icons = false,
                    offsets = {
                        { filetype = 'Yanil', text = 'File Explorer', text_align = 'left' },
                        { filetype = 'vista_kind', text = 'Vista', text_align = 'right' },
                    },
                },
                highlights = {
                    fill = {
                        bg = '#282828',
                    },
                    separator_selected = {
                        fg = '#282828',
                    },
                    separator_visible = {
                        fg = '#282828',
                    },
                    separator = {
                        fg = '#282828',
                    },
                },
            })

            local set_keymap = vim.keymap.set
            local keymaps = {
                -- Magic buffer-picking mode
                ['<A-s>'] = ':BufferLinePick<CR>',
                -- Move to previous/next
                ['<Tab>'] = ':BufferLineCycleNext<CR>',
                ['<S-Tab>'] = ':BufferLineCyclePrev<CR>',
                -- Re-order to previous/next
                ['<A-h>'] = ':BufferLineMovePrev<CR>',
                ['<A-l>'] = ':BufferLineMoveNext<CR>',
                -- Sort automatically by...
                ['<Leader>bd'] = ':BufferLineSortByDirectory<CR>',
                ['<Leader>bl'] = ':BufferLineSortByExtension<CR>',
            }

            for k, a in pairs(keymaps) do
                set_keymap('n', k, a, { silent = true, noremap = true })
            end
            local function gen_goto(idx)
                return function()
                    bufferline.go_to_buffer(idx)
                end
            end

            -- Goto buffer in position...
            for i = 1, 10, 1 do
                set_keymap('n', string.format('<A-%d>', i), gen_goto(i), { silent = true, noremap = false })
            end
        end,
    },

    {
        'numToStr/FTerm.nvim',
        keys = { '<A-o>' },
        config = function()
            local fterm = require('FTerm')
            fterm.setup({
                border = 'rounded',
                blend = 10,
                dimensions = {
                    height = 0.9,
                    widgets = 0.9,
                },
            })

            local opts = { noremap = false, silent = true }
            vim.keymap.set({ 'n', 't' }, '<A-o>', fterm.toggle, opts)
        end,
    },

    {
        'NTBBloodbath/galaxyline.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        branch = 'main',
        config = function()
            require('dotvim.config.statusline')
        end,
        dependencies = {
            -- 'kyazdani42/nvim-web-devicons',
        },
    },

    {
        'lukas-reineke/indent-blankline.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        opts = {
            -- char = "▏",
            har = '│',
            show_trailing_blankline_indent = false,
            show_current_context = false,
            show_first_indent_level = true,
            filetype_exclude = {
                'help',
                'lazy',
                'man',
                'vista',
                'vista_kind',
                'vista_markdown',
                'Yanil',
                'FTerm',
                'packer',
                'startify',
                'TelescopePrompt',
                'lsp-installer',
                'mason',
            },
            context_patterns = {
                'class',
                'function',
                'method',
                'table',
                'array',
                'body',
                'type',
                '^with',
                '^try',
                '^except',
                '^catch',
                '^if',
                '^else',
                '^while',
                '^for',
                '^loop',
                '^call',
            },
        },
    },

    -- active indent guide and indent text objects
    {
        'echasnovski/mini.indentscope',
        version = false, -- wait till new 0.7.0 release to put it back on semver
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            symbol = '│',
            options = { try_as_border = true },
        },
        init = function()
            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'help', 'Yanil', 'lazy', 'mason', 'terminal' },
                callback = function()
                    vim.b.miniindentscope_disable = true
                end,
            })
        end,
        config = function(_, opts)
            require('mini.indentscope').setup(opts)
        end,
    },

    {
        'MunifTanjim/nui.nvim',
        lazy = true,
    },

    {
        'windwp/nvim-spectre',
        event = 'VeryLazy',
        dependencies = { 'plenary', 'popup' },
        config = function()
            require('spectre').setup({})

            local set_keymap = vim.api.nvim_set_keymap

            local opts = { noremap = true, silent = true }
            set_keymap('n', '<leader>S', ':lua require("spectre").open()<CR>', opts)
            set_keymap('n', '<leader>Sc', 'viw:lua require("spectre").open_file_search()<CR>', opts)

            local group_id = vim.api.nvim_create_augroup('dotvim_spectre', { clear = true })

            vim.api.nvim_create_autocmd({ 'FileType' }, {
                group = group_id,
                pattern = { 'spectre_panel' },
                callback = function()
                    vim.cmd('setlocal nofoldenable')
                    vim.keymap.set('n', 'q', '<cmd>q<cr>', { silent = true, buffer = true })
                end,
            })
        end,
    },

    {
        'stevearc/dressing.nvim',
        lazy = true,
        init = function()
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.select = function(...)
                require('lazy').load({ plugins = { 'dressing.nvim' } })
                return vim.ui.select(...)
            end
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.ui.input = function(...)
                require('lazy').load({ plugins = { 'dressing.nvim' } })
                return vim.ui.input(...)
            end
        end,
        config = function()
            require('dressing').setup({
                input = {
                    -- Set to false to disable the vim.ui.input implementation
                    enabled = true,
                    -- Default prompt string
                    default_prompt = 'Input:',
                    -- Can be 'left', 'right', or 'center'
                    prompt_align = 'left',
                    -- When true, <Esc> will close the modal
                    insert_only = true,
                    -- These are passed to nvim_open_win
                    anchor = 'SW',
                    border = 'rounded',
                    -- 'editor' and 'win' will default to being centered
                    relative = 'cursor',
                    -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                    prefer_width = 40,
                    width = nil,
                    -- min_width and max_width can be a list of mixed types.
                    -- min_width = {20, 0.2} means "the greater of 20 columns or 20% of total"
                    max_width = { 140, 0.9 },
                    min_width = { 20, 0.2 },
                    win_options = {
                        -- Window transparency (0-100)
                        winblend = 10,
                        -- Change default highlight groups (see :help winhl)
                        winhighlight = '',
                    },
                    override = function(conf)
                        -- This is the config that will be passed to nvim_open_win.
                        -- Change values here to customize the layout
                        return conf
                    end,
                    -- see :help dressing_get_config
                    get_config = nil,
                },
                select = {
                    -- Set to false to disable the vim.ui.select implementation
                    enabled = true,
                    -- Priority list of preferred vim.select implementations
                    backend = { 'telescope', 'fzf_lua', 'fzf', 'builtin', 'nui' },
                    -- Options for telescope selector
                    -- These are passed into the telescope picker directly. Can be used like:
                    -- telescope = require('telescope.themes').get_ivy({...})
                    telescope = require('telescope.themes').get_dropdown({}),
                    -- Options for fzf selector
                    fzf = {
                        window = {
                            width = 0.5,
                            height = 0.4,
                        },
                    },
                    -- Options for fzf_lua selector
                    fzf_lua = {
                        winopts = {
                            width = 0.5,
                            height = 0.4,
                        },
                    },
                    -- Options for nui Menu
                    nui = {
                        position = '50%',
                        size = nil,
                        relative = 'editor',
                        border = {
                            style = 'rounded',
                        },
                        max_width = 80,
                        max_height = 40,
                    },
                    -- Options for built-in selector
                    builtin = {
                        -- These are passed to nvim_open_win
                        anchor = 'NW',
                        border = 'rounded',
                        -- 'editor' and 'win' will default to being centered
                        relative = 'editor',
                        win_options = {
                            -- Window transparency (0-100)
                            winblend = 10,
                            -- Change default highlight groups (see :help winhl)
                            winhighlight = '',
                        },
                        -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
                        -- the min_ and max_ options can be a list of mixed types.
                        -- max_width = {140, 0.8} means "the lesser of 140 columns or 80% of total"
                        width = nil,
                        max_width = { 140, 0.8 },
                        min_width = { 40, 0.2 },
                        height = nil,
                        max_height = 0.9,
                        min_height = { 10, 0.2 },
                        override = function(conf)
                            -- This is the config that will be passed to nvim_open_win.
                            -- Change values here to customize the layout
                            return conf
                        end,
                    },
                    -- Used to override format_item. See :help dressing-format
                    format_item_override = {},
                    -- see :help dressing_get_config
                    get_config = nil,
                },
            })
        end,
    },

    {
        'kevinhwang91/nvim-hlslens',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            require('hlslens').setup()
            local kopts = { noremap = true, silent = true }

            vim.keymap.set('n', 'n', [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
            vim.keymap.set('n', 'N', [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]], kopts)
            vim.keymap.set('n', '*', [[*<Cmd>lua require('hlslens').start()<CR>]], kopts)
            vim.keymap.set('n', '#', [[#<Cmd>lua require('hlslens').start()<CR>]], kopts)
            vim.keymap.set('n', 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], kopts)
            vim.keymap.set('n', 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], kopts)
        end,
    },

    {
        'folke/todo-comments.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = 'plenary',
        config = function()
            require('todo-comments').setup({
                keywords = {
                    FIX = {
                        icon = ' ', -- icon used for the sign, and in search results
                        color = 'error', -- can be a hex color, or a named color (see below)
                        alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' }, -- a set of other keywords that all map to this FIX keywords
                        -- signs = false, -- configure signs for some keywords individually
                    },
                    TODO = { icon = ' ', color = 'info' },
                    HACK = { icon = ' ', color = 'warning' },
                    WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
                    PERF = { icon = ' ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
                    NOTE = { icon = ' ', color = 'hint', alt = { 'INFO' } },
                    TEST = { icon = '⏲ ', color = 'test', alt = { 'TESTING', 'PASSED', 'FAILED' } },
                },
                highlight = {
                    before = '', -- "fg" or "bg" or empty
                    keyword = 'wide', -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
                    after = 'fg', -- "fg" or "bg" or empty
                    pattern = [[.*<(KEYWORDS):?\s+]], -- pattern or table of patterns, used for highlightng (vim regex)
                    comments_only = true, -- uses treesitter to match keywords in comments only
                    max_line_len = 400, -- ignore lines longer than this
                    exclude = {}, -- list of file types to exclude highlighting
                },
                search = {
                    command = 'rg',
                    args = {
                        '--color=never',
                        '--no-heading',
                        '--with-filename',
                        '--line-number',
                        '--column',
                    },
                    -- regex that will be used to match keywords.
                    -- don't replace the (KEYWORDS) placeholder
                    -- pattern = [[\b(KEYWORDS):]], -- ripgrep regex
                    pattern = [[\b(KEYWORDS):?\b]], -- match without the extra colon. You'll likely get false positives
                },
            })
        end,
    },

    {
        'lukas-reineke/headlines.nvim',
        ft = { 'markdown', 'orgmode', 'neorg' },
        config = function()
            require('headlines').setup()
        end,
    },

    {
        'eandrju/cellular-automaton.nvim',
        cmd = { 'CellularAutomaton' },
    },

    {
        'akinsho/git-conflict.nvim',
        version = '*',
        event = 'VeryLazy',
        config = function()
            require('git-conflict').setup({
                default_mappings = {
                    ours = '<leader>co',
                    theirs = '<leader>ct',
                    none = '<leader>c0',
                    both = '<leader>cb',
                    next = ']x',
                    prev = '[x',
                },
                default_commands = true,
            })
        end,
    },

    {
        'folke/drop.nvim',
        event = { 'CursorHold' },
        cmd = { 'DropShow' },
        config = function()
            require('drop').setup({
                theme = 'leaves',
                max = 40,
                interval = 100,
                screensaver = 1000 * 60 * 3,
                filetypes = {
                    'dashboard',
                    'alpha',
                    'starter',
                }, -- will enable/disable automatically for the following filetypes
            })
            vim.api.nvim_create_user_command('DropShow', function()
                require('drop').show()
            end, {})
            vim.api.nvim_create_user_command('DropHide', function()
                require('drop').hide()
            end, {})
        end,
    },
}
