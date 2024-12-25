local conditions = require('heirline.conditions')
local utils = require('heirline.utils')

local components = require('dotvim.config.heirline.components')
local colors = require('dotvim.config.heirline.colors')

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
        condition = function()
            return vim.o.laststatus < 3 and conditions.is_not_active()
        end,
        components.FileType,
        components.Space,
        components.FileNameBlock,
        components.Align,
    }
    local special = {
        condition = function()
            return conditions.buffer_matches({
                buftype = { 'nofile', 'prompt', 'help', 'quickfix' },
                filetype = { 'gitcommit', 'startify' },
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

function M.winbar()
    return {
        condition = conditions.lsp_attached,
        components.Navic,
    }
end

function M.setup()
    local heirline = require('heirline')
    heirline.setup({
        opts = {
            colors = colors.get,
            disable_winbar_cb = function(args)
                return vim.bo[args.buf].buftype ~= '' or vim.bo[args.buf].filetype == 'gitcommit'
            end,
        },
        statusline = M.statusline(),
        winbar = M.winbar(),
    })

    local group_id = vim.api.nvim_create_augroup('dotvim_heirline', { clear = true })
    vim.api.nvim_create_autocmd('ColorScheme', {
        group = group_id,
        callback = function()
            colors.update()
            utils.on_colorscheme(colors.get)
        end,
    })

    vim.api.nvim_create_autocmd('User', {
        group = group_id,
        pattern = 'DotVimGitHeadUpdate',
        callback = vim.schedule_wrap(function()
            vim.cmd('redrawstatus')
        end),
    })
end

return M
