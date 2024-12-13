local features = require('dotvim.features')

return {
    {
        'rebelot/kanagawa.nvim',
        lazy = false,
        config = function()
            local theme = 'wave'

            local kanagawa = require('kanagawa')
            kanagawa.setup({
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
                overrides = function(colors)
                    return {
                        YanilTreeDirectory = { fg = colors.palette.springGreen, bold = true },
                        YanilTreeFile = { fg = colors.palette.fujiWhite },
                        DapCustomPC = { fg = colors.palette.autumnGreen },
                        DapBreakpoint = { fg = colors.palette.autumnRed },
                        DapBreakpointCondition = { fg = colors.palette.autumnYellow },
                        DapBreakpointReject = { fg = colors.palette.fujiGray },
                        DapLogPoint = { fg = colors.palette.autumnRed },
                        LspSignatureActiveParameter = { underline = true },
                        Conceal = { bold = false, italic = false },

                        FloatBorder = { bg = 'NONE' },
                        FloatTitle = { bg = 'NONE' },
                        NormalFloat = { bg = 'NONE' },
                        TelescopeBorder = { bg = 'NONE' },
                        TelescopePreviewLine = { bg = colors.palette.sumiInk6 },

                        CmpItemKindNamespace = { link = '@lsp.type.namespace' },
                        CmpItemKindPackage = { link = '@module' },
                        CmpItemKindConstant = { link = 'Constant' },
                        CmpItemKindString = { link = 'String' },
                        CmpItemKindNumber = { link = 'Number' },
                        CmpItemKindBoolean = { link = 'Boolean' },
                        -- CmpItemKindArray         = {},
                        -- CmpItemKindObject        = {},
                        -- CmpItemKindKey           = {},
                        -- CmpItemKindNull          = {},
                    }
                end,
                theme = theme,
            })

            vim.cmd('colorscheme kanagawa')
        end,
    },
}
