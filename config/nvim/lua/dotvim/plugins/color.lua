return {
    {
        'rebelot/kanagawa.nvim',
        config = function()
            local colors = require('kanagawa.colors').setup()

            local overrides = {
                YanilTreeDirectory = { fg = colors.springGreen, bold = true },
                YanilTreeFile = { fg = colors.fujiWhite },
            }

            local kanagawa = require('kanagawa')
            kanagawa.setup({
                undercurl = true, -- enable undercurls
                commentStyle = { italic = false },
                -- functionStyle = {},
                keywordStyle = { italic = true, bold = true },
                statementStyle = { bold = true },
                -- typeStyle = {},
                variablebuiltinStyle = { italic = true },
                specialReturn = true, -- special highlight for the return keyword
                specialException = true, -- special highlight for exception handling keywords
                transparent = false,
                colors = colors,
                overrides = overrides,
            })
            local colors = kanagawa.config.colors
            local dotcolors = require('dotvim.colors')
            dotcolors.enable_auto_update()

            dotcolors.colors.Git.Add = colors.git.added
            dotcolors.colors.Git.Delete = colors.git.removed
            dotcolors.colors.Git.Change = colors.git.changed

            dotcolors.colors.Diagnostic.Error = colors.diag.error
            dotcolors.colors.Diagnostic.Warn = colors.diag.warning
            dotcolors.colors.Diagnostic.Info = colors.diag.info
            dotcolors.colors.Diagnostic.Hint = colors.diag.hint

            vim.cmd('colorscheme kanagawa')
        end,
    },
}
