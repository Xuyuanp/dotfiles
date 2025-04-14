local features = require('dotvim.features')

return {
    {
        'rebelot/kanagawa.nvim',
        lazy = false,
        opts = {
            theme = 'wave',
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
                            bg_gutter = 'NONE',
                            float = {
                                bg = 'NONE',
                                bg_border = 'NONE',
                            },
                        },
                    },
                },
            },
            ---@param colors KanagawaColors
            overrides = function(colors)
                local theme = colors.theme
                return {
                    Directory = { bold = true },
                    ['@comment.documentation'] = { link = 'SpecialComment' },

                    ['@markup.heading'] = { bold = true, fg = theme.syn.fun },

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
                    LspCodeLens = { fg = theme.ui.special },

                    TelescopeBorder = { bg = 'NONE' },

                    ScrollbarHead = { fg = theme.ui.nontext, bg = 'NONE', italic = false, bold = false },
                    ScrollbarBody = { fg = theme.ui.nontext, bg = 'NONE', italic = false, bold = false },
                    ScrollbarTail = { fg = theme.ui.nontext, bg = 'NONE', italic = false, bold = false },

                    NesDelete = { bg = theme.diff.delete },
                    NesAdd = { bg = theme.diff.add },
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
