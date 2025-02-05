local features = require('dotvim.features')

return {
    {
        'rebelot/kanagawa.nvim',
        lazy = false,
        opts = {
            theme = 'wave',
            compile = true,
            undercurl = true, -- enable undercurls
            commentStyle = { italic = false },
            functionStyle = {},
            keywordStyle = { italic = true, bold = true },
            statementStyle = { bold = true },
            typeStyle = {},
            variablebuiltinStyle = { italic = true },
            specialReturn = true, -- special highlight for the return keyword
            specialException = true, -- special highlight for exception handling keywords
            transparent = features.transparent,
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg_gutter = 'none',
                        },
                    },
                },
            },
            ---@param colors KanagawaColors
            overrides = function(colors)
                local theme = colors.theme
                return {
                    Directory = { bold = true },

                    FloatBorder = { bg = 'NONE' },
                    FloatTitle = { bg = 'NONE' },
                    NormalFloat = { bg = 'NONE' },

                    CursorLine = { bg = theme.ui.bg_p1 },
                    Visual = { bg = theme.ui.bg_m1 },

                    YanilTreeDirectory = { link = 'Directory' },
                    YanilTreeFile = { fg = theme.ui.fg },

                    DapCustomPC = { fg = theme.diag.ok },
                    DapBreakpoint = { fg = theme.diag.error },
                    DapBreakpointCondition = { fg = theme.diag.warning },
                    DapBreakpointReject = { fg = theme.diff.delete },
                    DapLogPoint = { fg = theme.diag.info },

                    LspSignatureActiveParameter = { underline = true, bold = true, italic = true },

                    TelescopeBorder = { bg = 'NONE' },
                }
            end,
        },
        config = function(_, opts)
            local kanagawa = require('kanagawa')
            kanagawa.setup(opts)

            vim.cmd('colorscheme kanagawa')
        end,
    },
}
