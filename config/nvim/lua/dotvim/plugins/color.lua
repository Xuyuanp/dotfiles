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

                    ScrollbarHead = { fg = theme.syn.comment, bg = 'NONE', italic = false, bold = false },
                    ScrollbarBody = { fg = theme.syn.comment, bg = 'NONE', italic = false, bold = false },
                    ScrollbarTail = { fg = theme.syn.comment, bg = 'NONE', italic = false, bold = false },
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
