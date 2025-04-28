local lazy_require = require('dotvim.util').lazy_require

return {
    {
        'Xuyuanp/sqlx-rs.nvim',
        ft = { 'rust' },
        cmd = { 'SqlxFormat' },
        build = function()
            vim.fn.system({
                'pip',
                'install',
                '-U',
                'sqlparse',
            })
        end,
        opts = {},
        config = function(_, opts)
            local sqlx = require('sqlx')
            sqlx.setup(opts)

            vim.api.nvim_create_autocmd('BufWritePre', {
                pattern = '*.rs',
                group = vim.api.nvim_create_augroup('dotvim.sqlx-rs', { clear = true }),
                command = 'SqlxFormat',
                desc = '[sqlx-rs] format on save',
            })
        end,
    },

    {
        'Xuyuanp/yanil',
        dev = true,
        branch = 'main',
        keys = {
            { '<C-e>', require('dotvim.util').lazy_require('yanil.canvas').toggle, mode = 'n', desc = '[Yanil] toggle' },
        },
        config = function()
            require('dotvim.config.yanil').setup()

            local group_id = vim.api.nvim_create_augroup('dotvim.yanil', { clear = true })
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
                    require('yanil.git').update()
                end,
            })
        end,
    },

    {
        'Xuyuanp/floaterm.nvim',
        keys = {
            {
                '<A-o>',
                lazy_require('floaterm').toggle,
                mode = { 'n', 't' },
                desc = '[Floaterm] toggle',
            },
        },
        opts = {},
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
                head = 'ScrollbarHead',
                body = 'ScrollbarBody',
                tail = 'ScrollbarTail',
            }
            vim.g.scrollbar_shape = {
                -- head = '⍋',
                -- tail = '⍒',
                head = '┃',
                body = '┃',
                tail = '┃',
            }

            local group_id = vim.api.nvim_create_augroup('dotvim.scrollbar', { clear = true })

            vim.api.nvim_create_autocmd({ 'WinScrolled', 'WinResized', 'InsertLeave' }, {
                group = group_id,
                desc = '[Scrollbar] show',
                pattern = { '*' },
                callback = function()
                    require('scrollbar').show()
                end,
            })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI', 'InsertEnter' }, {
                group = group_id,
                desc = '[Scrollbar] hide',
                callback = function()
                    require('scrollbar').clear()
                end,
            })
        end,
    },

    {
        'Xuyuanp/nes.nvim',
        lazy = false,
        branch = 'feat/lsp-api',
        config = function()
            vim.lsp.enable('nes')

            local function request_nes()
                local client = vim.lsp.get_clients({ name = 'nes' })[1]
                if not client then
                    return
                end
                require('copilot-lsp.nes').request_nes(client)
            end

            local debounced_fn = require('copilot-lsp.util').debounce(request_nes, 500)
            local group = vim.api.nvim_create_augroup('dotvim.nes.blink', { clear = true })
            vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
                group = group,
                desc = '[Nes] auto trigger',
                callback = function()
                    debounced_fn()
                end,
            })
        end,
        keys = {
            {
                '<A-i>',
                function()
                    local client = vim.lsp.get_clients({ name = 'nes' })[1]
                    if not client then
                        return
                    end
                    require('copilot-lsp.nes').request_nes(client)
                end,
                mode = 'i',
                desc = '[Nes] get suggestion',
            },
        },
    },
}
