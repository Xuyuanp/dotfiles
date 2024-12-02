local conditions = require('heirline.conditions')

local components = require('dotvim.config.heirline.components')
local colors = require('dotvim.config.heirline.colors')
require('dotvim.util.git').load_head()

local M = {}

function M.statusline()
    local default = {
        components.VimMode,
        components.Space,
        components.FileNameBlock,
        components.Git,
        components.Diagnostics,
        components.Align,

        components.LSPActive,
        components.Space,
        components.FileEncoding,
        components.Space,
        components.FileType,
        components.Space,
        components.Ruler,
        components.Space,
        components.Percent,
        components.Space,
        components.ScrollBar,
    }
    local inactive = {
        condition = conditions.is_not_active,
        components.FileType,
        components.Space,
        components.FileName,
        components.Align,
    }
    local special = {
        condition = function()
            return conditions.buffer_matches({
                buftype = { 'nofile', 'prompt', 'help', 'quickfix' },
                filetype = { '^git.*', 'fugitive', 'startify' },
            })
        end,
        components.FileType,
        components.Align,
    }
    local terminal = {
        condition = function()
            return conditions.buffer_matches({ buftype = { 'terminal' } })
        end,

        {
            condition = conditions.is_active,
            components.VimMode,
            components.Space,
        },
        components.FileType,
        components.Space,
        components.TerminalName,
        components.Align,
    }
    return {
        hl = function()
            if conditions.is_active() then
                return 'StatusLine'
            else
                return 'StatusLineNC'
            end
        end,
        fallthrough = false,

        special,
        terminal,
        inactive,
        default,
    }
end

function M.setup()
    local heirline = require('heirline')
    heirline.setup({
        opts = {
            colors = colors.get(),
        },
        statusline = M.statusline(),
    })

    vim.api.nvim_create_autocmd('ColorScheme', {
        callback = function()
            heirline.reset_highlights()
            heirline.load_colors(colors.get())
        end,
    })
end

return M
