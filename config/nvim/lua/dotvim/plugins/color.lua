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

            local dotcolors = require('dotvim.util.colors')
            dotcolors.enable_auto_update()

            local colors = require('kanagawa.colors').setup({ theme = theme })
            dotcolors.colors.Git.Add = colors.theme.vcs.added
            dotcolors.colors.Git.Delete = colors.theme.vcs.removed
            dotcolors.colors.Git.Change = colors.theme.vcs.changed

            dotcolors.colors.Diagnostic.Error = colors.theme.diag.error
            dotcolors.colors.Diagnostic.Warn = colors.theme.diag.warning
            dotcolors.colors.Diagnostic.Info = colors.theme.diag.info
            dotcolors.colors.Diagnostic.Hint = colors.theme.diag.hint

            vim.cmd('colorscheme kanagawa')
        end,
    },
}
