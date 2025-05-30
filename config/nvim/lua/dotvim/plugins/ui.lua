local vim = vim

return {
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
            vim.cmd([[
            autocmd User Startified setlocal buftype=nofile
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
                { '<A-s>', '<cmd>BufferLinePick<CR>', 'magic buffer-picking' },
                -- Move to previous/next
                { '<Tab>', '<cmd>BufferLineCycleNext<CR>', 'move to next' },
                { '<S-Tab>', '<cmd>BufferLineCyclePrev<CR>', 'move to previous' },
                -- Re-order to previous/next
                { '<A-h>', '<cmd>BufferLineMovePrev<CR>', 'reorder to previous' },
                { '<A-l>', '<cmd>BufferLineMoveNext<CR>', 'reorder to next' },
                -- Sort automatically by...
                { '<Leader>bd', '<cmd>BufferLineSortByDirectory<CR>', 'sort automatically by directory' },
                { '<Leader>bl', '<cmd>BufferLineSortByExtension<CR>', 'sort automatically by extension' },
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
            for i = 1, 9, 1 do
                vim.keymap.set('n', string.format('<A-%d>', i), gen_goto(i), { desc = string.format('[BufferLine] goto buffer %d', i) })
            end
        end,
    },

    {
        'SmiteshP/nvim-navic',
        init = function()
            require('dotvim.config.lsp.utils').on_attach(function(client, bufnr)
                if not client:supports_method(vim.lsp.protocol.Methods.textDocument_documentSymbol) then
                    return
                end

                require('nvim-navic').attach(client, bufnr)
            end)
        end,
        opts = {
            depth_limit = 5,
            highlight = true,
        },
    },

    {
        'rebelot/heirline.nvim',
        dependencies = {
            'echasnovski/mini.icons',
            'SmiteshP/nvim-navic',
        },
        event = 'UiEnter',
        config = function()
            require('dotvim.config.heirline').setup()
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

            local group_id = vim.api.nvim_create_augroup('dotvim.spectre', { clear = true })

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
        'kevinhwang91/nvim-hlslens',
        event = 'VeryLazy',
        opts = {},
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
                                    gitsigns.nav_hunk('next', { preview = true })
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
                                    gitsigns.nav_hunk('prev', { preview = true })
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
                            desc = '[Gitsigns] ' .. spec.desc,
                        })
                    end

                    local root = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.root or vim.fn.getcwd()
                    require('dotvim.util.git').load_head(bufnr, root)
                end,
            })

            vim.api.nvim_create_autocmd('WinClosed', {
                group = vim.api.nvim_create_augroup('dotvim.gitsigns.refresh', { clear = true }),
                callback = function(args)
                    if not vim.api.nvim_buf_is_valid(args.buf) then
                        return
                    end
                    if vim.bo[args.buf].buftype ~= 'terminal' then
                        return
                    end
                    require('gitsigns').refresh()
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
        opts_extend = { 'spec' },
        opts = {
            preset = 'modern',
            spec = {
                {
                    mode = { 'n', 'v' },
                    { '[', group = 'prev' },
                    { ']', group = 'next' },
                    { 'z', group = 'fold' },
                    {
                        '<leader>b',
                        group = 'buffer',
                        expand = function()
                            return require('which-key.extras').expand.buf()
                        end,
                    },
                    {
                        '<leader>w',
                        group = 'windows',
                        proxy = '<c-w>',
                        expand = function()
                            return require('which-key.extras').expand.win()
                        end,
                    },
                    -- better descriptions
                    { 'gx', desc = 'Open with system app' },
                },
            },
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
        event = 'VeryLazy',
        keys = {
            {
                ']z',
                function()
                    local ufo = require('ufo')
                    ufo.goNextClosedFold()
                    ufo.peekFoldedLinesUnderCursor(true)
                end,
                desc = '[Ufo] got to next fold',
            },
            {
                '[z',
                function()
                    local ufo = require('ufo')
                    ufo.goPreviousClosedFold()
                    ufo.peekFoldedLinesUnderCursor(true)
                end,
                desc = '[Ufo] got to previous fold',
            },
        },
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
            preview = {
                win_config = {
                    winblend = vim.o.winblend,
                },
                mappings = {
                    scrollU = '<C-u>',
                    scrollD = '<C-d>',
                    jumpTop = '[',
                    jumpBot = ']',
                },
            },
            provider_selector = function(bufnr)
                local clients = vim.lsp.get_clients({
                    bufnr = bufnr,
                    method = vim.lsp.protocol.Methods.textDocument_foldingRange,
                })
                local main = next(clients) and 'lsp' or 'treesitter'
                return { main, 'indent' }
            end,
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
