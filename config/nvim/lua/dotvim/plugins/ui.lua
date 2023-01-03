return {

    {
        'nvim-telescope/telescope.nvim',
        as = 'telescope',
        requires = {
            'popup',
            'plenary',
        },
        config = function()
            require('dotvim.telescope').setup()
        end,
    },

    {
        'Xuyuanp/yanil',
        config = function()
            require('dotvim/yanil').setup()

            local vim = vim
            local execute = vim.api.nvim_command

            execute([[ nmap <C-e> :YanilToggle<CR> ]])

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
        requires = {
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
        command = ':Vista',
        config = function()
            vim.g.vista_default_executive = 'nvim_lsp'
            vim.api.nvim_set_keymap('n', '<C-t>', ':Vista!!<CR>', { noremap = true })
        end,
    },

    {
        'norcalli/nvim-colorizer.lua',
        event = 'BufEnter',
        config = function()
            vim.opt.termguicolors = true
            require('colorizer').setup()
        end,
    },

    {
        'Xuyuanp/scrollbar.nvim',
        event = 'BufEnter',
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
        -- requires = 'kyazdani42/nvim-web-devicons',
        event = 'BufEnter',
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
        'sunjon/shade.nvim',
        event = 'BufEnter',
        config = function()
            if vim.fn.has('gui') then
                return
            end
            require('shade').setup({
                overlay_opacity = 70,
                opacity_step = 5,
                keys = {
                    brightness_up = '<C-Up>', -- FIXME: conflict with vim-visual-multi
                    brightness_down = '<C-Down>',
                    toggle = '<Leader>s',
                },
            })
        end,
    },

    {
        'nvim-treesitter/nvim-treesitter',
        requires = {
            'nvim-treesitter/playground',
            'romgrk/nvim-treesitter-context',
            'p00f/nvim-ts-rainbow',
        },
        run = ':TSUpdate',
        config = function()
            require('dotvim.treesitter').setup()
        end,
    },

    {
        'haringsrob/nvim_context_vt',
        requires = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('nvim_context_vt').setup({
                -- Enable by default. You can disable and use :NvimContextVtToggle to maually enable.
                -- Default: true
                enabled = true,

                -- Disable virtual text for given filetypes
                -- Default: { 'markdown' }
                disable_ft = { 'markdown' },

                -- Disable display of virtual text below blocks for indentation based languages like Python
                -- Default: false
                disable_virtual_lines = false,

                -- Same as above but only for spesific filetypes
                -- Default: {}
                disable_virtual_lines_ft = { 'yaml', 'python' },

                -- How many lines required after starting position to show virtual text
                -- Default: 1 (equals two lines total)
                min_rows = 80,
            })
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
        event = 'BufEnter',
        branch = 'main',
        config = function()
            require('dotvim.statusline')
        end,
        requires = {
            -- 'kyazdani42/nvim-web-devicons',
        },
    },

    {
        'lukas-reineke/indent-blankline.nvim',
        event = 'BufEnter',
        setup = function()
            vim.wo.colorcolumn = '99999'

            vim.g.indent_blankline_char = '│'
            vim.g.indent_blankline_use_treesitter = true
            vim.g.indent_blankline_show_first_indent_level = true
            vim.g.indent_blankline_show_trailing_blankline_indent = true
            vim.g.indent_blankline_filetype_exclude = {
                'help',
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
            }

            vim.g.indent_blankline_show_current_context = true
            vim.g.indent_blankline_context_patterns = {
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
            }
        end,
    },

    {
        'MunifTanjim/nui.nvim',
    },

    {
        'windwp/nvim-spectre',
        requires = { 'plenary', 'popup' },
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
        'm-demare/hlargs.nvim',
        requires = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('hlargs').setup({})
        end,
    },

    {
        'folke/todo-comments.nvim',
        requires = 'plenary',
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
        config = function()
            require('headlines').setup()
        end,
    },
}
