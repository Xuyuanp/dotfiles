local vim = vim

return {
    {
        'nvim-telescope/telescope.nvim',
        cmd = { 'Telescope' },
        dependencies = {
            'nvim-lua/popup.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-file-browser.nvim',
        },
        keys = {
            { '<A-l>', '<cmd>Telescope file_browser<CR>', mode = 'n', desc = '[Telescope] file browser' },
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
                    prompt_prefix = ' 󰍉 ',
                    selection_caret = ' ',
                },
                extensions = {
                    file_browser = {
                        git_status = true,
                    },
                },
            })

            require('telescope').load_extension('file_browser')

            local group_id = vim.api.nvim_create_augroup('dotvim_telescope', { clear = true })
            vim.api.nvim_create_autocmd('User', {
                group = group_id,
                pattern = 'TelescopePreviewerLoaded',
                callback = function()
                    vim.wo.number = true
                end,
            })
        end,
    },

    {
        'Xuyuanp/yanil',
        dev = true,
        branch = 'main',
        keys = {
            { '<C-e>', require('dotvim.util').lazy_require('yanil/canvas').toggle, mode = 'n', desc = '[Yanil] toggle' },
        },
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('dotvim.config.yanil').setup()

            local group_id = vim.api.nvim_create_augroup('dotvim_yanil', { clear = true })
            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                group = group_id,
                desc = 'Auto quit yanil',
                pattern = { 'Yanil' },
                command = 'if len(nvim_list_wins()) ==1 | q | endif',
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'GitSignsUpdate',
                group = group_id,
                desc = 'Auto refresh git status of Yanil',
                callback = function()
                    require('yanil/git').update()
                end,
            })
        end,
    },

    {
        'mhinz/vim-startify',
        lazy = vim.fn.argc() > 0,
        dependencies = {
            'echasnovski/mini.icons',
        },
        config = function()
            local vfn = vim.fn

            _G.startify_get_icon = function(path)
                local filename = vfn.fnamemodify(path, ':t')
                return require('mini.icons').get('file', filename)
            end

            vim.cmd([[
            function! StartifyEntryFormat()
                return 'v:lua.startify_get_icon(absolute_path) ." ". entry_path'
            endfunction
            ]])
        end,
    },

    {
        'liuchengxu/vista.vim',
        keys = { { '<C-t>', ':Vista!!<CR>', mode = 'n', desc = '[Vista] toggle' } },
        config = function()
            vim.g.vista_default_executive = 'nvim_lsp'
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
        init = function()
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
        version = 'v4',
        dependencies = {
            'echasnovski/mini.icons',
        },
        event = { 'BufReadPost', 'BufNewFile' },
        ---@type bufferline.UserConfig
        opts = {
            options = {
                mode = 'buffers',
                themable = true,
                numbers = 'ordinal',
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
        },
        config = function(_, opts)
            local bufferline = require('bufferline')
            bufferline.setup(opts)

            local keymaps = {
                -- Magic buffer-picking mode
                { '<A-s>', ':BufferLinePick<CR>', 'magic buffer-picking' },
                -- Move to previous/next
                { '<Tab>', ':BufferLineCycleNext<CR>', 'move to next' },
                { '<S-Tab>', ':BufferLineCyclePrev<CR>', 'move to previous' },
                -- Re-order to previous/next
                { '<A-h>', ':BufferLineMovePrev<CR>', 'reorder to previous' },
                { '<A-l>', ':BufferLineMoveNext<CR>', 'reorder to next' },
                -- Sort automatically by...
                { '<Leader>bd', ':BufferLineSortByDirectory<CR>', 'sort automatically by directory' },
                { '<Leader>bl', ':BufferLineSortByExtension<CR>', 'sort automatically by extension' },
            }

            for _, spec in pairs(keymaps) do
                vim.keymap.set('n', spec[1], spec[2], { silent = true, remap = false, desc = '[BufferLine] ' .. spec[3] })
            end
            local function gen_goto(idx)
                return function()
                    bufferline.go_to(idx, true)
                end
            end

            -- Goto buffer in position...
            for i = 1, 10, 1 do
                vim.keymap.set('n', string.format('<A-%d>', i), gen_goto(i), { desc = string.format('[BufferLine] goto buffer %d', i) })
            end
        end,
    },

    {
        'numToStr/FTerm.nvim',
        keys = {
            {
                '<A-o>',
                require('dotvim.util').lazy_require('FTerm').toggle,
                mode = { 'n', 't' },
                desc = '[FTerm] toggle',
            },
        },
        opts = {
            border = 'rounded',
            dimensions = {
                height = 0.9,
                widgets = 0.9,
            },
        },
    },

    {
        'rebelot/heirline.nvim',
        dependencies = {
            'echasnovski/mini.icons',
        },
        event = 'UiEnter',
        config = function()
            require('dotvim.config.heirline').setup()
        end,
    },

    {
        'lukas-reineke/indent-blankline.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        version = 'v2',
        opts = {
            char = '│',
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
        version = '*',
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
        'windwp/nvim-spectre',
        keys = {
            {
                '<leader>S',
                require('dotvim.util').lazy_require('spectre').open,
                mode = 'n',
                noremap = true,
                silent = true,
                desc = '[Spectre] search',
            },
            {
                '<leader>Ss',
                function()
                    require('spectre').open_file_search({ select_word = true })
                end,
                mode = 'n',
                noremap = true,
                silent = true,
                desc = '[Spectre] search current word in file',
            },
        },
        dependencies = { 'nvim-lua/plenary.nvim', 'nvim-lua/popup.nvim' },
        config = function()
            require('spectre').setup({})

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
                    enabled = true,
                    default_prompt = 'Input:',
                    prompt_align = 'left',
                    border = 'rounded',
                },
                select = {
                    -- Set to false to disable the vim.ui.select implementation
                    enabled = true,
                    -- Priority list of preferred vim.select implementations
                    backend = { 'telescope', 'builtin' },
                    -- Options for telescope selector
                    -- These are passed into the telescope picker directly. Can be used like:
                    telescope = require('telescope.themes').get_dropdown({}),
                    -- Options for built-in selector
                    builtin = {
                        -- These are passed to nvim_open_win
                        border = 'rounded',
                        -- 'editor' and 'win' will default to being centered
                        relative = 'editor',
                    },
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
        dependencies = 'nvim-lua/plenary.nvim',
        opts = {
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
                PERF = { icon = '󰅒 ', alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' } },
                NOTE = { icon = '󰍨 ', color = 'hint', alt = { 'INFO' } },
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
        },
    },

    {
        'eandrju/cellular-automaton.nvim',
        cmd = { 'CellularAutomaton' },
    },

    {
        'akinsho/git-conflict.nvim',
        version = '*',
        event = 'User GitSigns*',
        opts = {
            default_mappings = {
                ours = '<leader>co',
                theirs = '<leader>ct',
                none = '<leader>c0',
                both = '<leader>cb',
                next = ']x',
                prev = '[x',
            },
            default_commands = true,
        },
    },

    {
        'lewis6991/gitsigns.nvim',
        version = '*',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local gitsigns = require('gitsigns')
            gitsigns.setup({
                signs = {
                    add = { text = '┃' },
                    change = { text = '┃' },
                    delete = { text = '┃' },
                    topdelete = { text = '┃' },
                    changedelete = { text = '┃' },
                    untracked = { text = '┃' },
                },
                current_line_blame = true,
                current_line_blame_formatter = '@<author> / <abbrev_sha> <summary> / <author_time:%R>',
                on_attach = function(bufnr)
                    local keymaps = {
                        {
                            ']c',
                            function()
                                if vim.wo.diff then
                                    vim.cmd.normal({ ']c', bang = true })
                                else
                                    gitsigns.nav_hunk('next')
                                end
                            end,
                            desc = 'jump to next hunk',
                        },
                        {
                            '[c',
                            function()
                                if vim.wo.diff then
                                    vim.cmd.normal({ '[c', bang = true })
                                else
                                    gitsigns.nav_hunk('prev')
                                end
                            end,
                            desc = 'jump to next hunk',
                        },
                        --  Text objects
                        { 'ih', gitsigns.select_hunk, mode = { 'x', 'o' }, desc = 'select hunk' },
                    }
                    for _, spec in ipairs(keymaps) do
                        vim.keymap.set(spec.mode or 'n', spec[1], spec[2], {
                            noremap = true,
                            silent = true,
                            buffer = bufnr,
                            desc = '[gitsigns] ' .. spec.desc,
                        })
                    end
                end,
            })
        end,
    },

    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            preset = 'modern',
        },
    },

    {
        'echasnovski/mini.icons',
        version = '*',
        opts = {},
        config = function(_, opts)
            local mini_icons = require('mini.icons')
            mini_icons.setup(opts)
            mini_icons.mock_nvim_web_devicons()
        end,
    },

    {
        'kevinhwang91/nvim-ufo',
        dependencies = 'kevinhwang91/promise-async',
        event = { 'BufReadPost', 'BufNewFile' },
        init = function()
            vim.opt.fillchars:append({
                fold = ' ',
                foldopen = '',
                foldsep = ' ',
                foldclose = '',
            })
            vim.o.foldcolumn = '0' -- disabled foldcolumn to avoid display the number of fold level
            vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
        end,
        opts = {
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, 'MoreMsg' })
                return newVirtText
            end,
            mappings = {
                scrollU = '<C-u>',
                scrollD = '<C-d>',
                jumpTop = '[',
                jumpBot = ']',
            },
        },
    },

    {
        'hiphish/rainbow-delimiters.nvim',
        event = { 'BufRead', 'BufNewFile' },
        config = function()
            local rainbow_delimiters = require('rainbow-delimiters')

            ---@type rainbow_delimiters.config
            vim.g.rainbow_delimiters = {
                strategy = {
                    [''] = rainbow_delimiters.strategy['global'],
                },
                query = {
                    [''] = 'rainbow-delimiters',
                },
                priority = {
                    [''] = 110,
                    lua = 210,
                },
                highlight = {
                    'RainbowDelimiterCyan',
                    'RainbowDelimiterOrange',
                    'RainbowDelimiterViolet',
                    'RainbowDelimiterGreen',
                    'RainbowDelimiterYellow',
                    'RainbowDelimiterBlue',
                    'RainbowDelimiterRed',
                },
            }
        end,
    },

    {
        'nvchad/menu',
        dependencies = {
            'nvchad/volt',
        },
        keys = {
            {
                '<A-m>',
                function()
                    require('menu').open('default', { mouse = false, border = true })
                end,
                mode = 'n',
                desc = 'Menu',
            },
        },
    },
}
