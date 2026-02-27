---@alias LspClient vim.lsp.Client
---@alias OnAttachFunc fun(client: LspClient, bufnr: number):boolean?

local function make_capabilities()
    if vim.g.dotvim_lsp_capabilities then
        return vim.g.dotvim_lsp_capabilities()
    end
    return require('dotvim.config.lsp.capabilities')
end

local M = {}

local backup = vim.lsp.util.convert_input_to_markdown_lines

-- fuck microsoft. https://github.com/microsoft/pylance-release/discussions/6631
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.util.convert_input_to_markdown_lines = function(input, contents)
    local extend = backup(input, contents)
    for i, line in ipairs(extend) do
        line = line:gsub('&nbsp;', ' ')
        line = line:gsub('\\_', '_')
        line = line:gsub('&gt;', '>')
        line = line:gsub('&lt;', '<')
        extend[i] = line
    end

    return extend
end

function M.setup()
    require('dotvim.config.lsp.buf').overwrite()
    require('dotvim.config.lsp.utils').setup()
    require('dotvim.config.lsp.keymaps').setup()
    require('dotvim.config.lsp.autocmds').setup()

    if vim.fn.has('nvim-0.12') == 1 then
        vim.lsp.on_type_formatting.enable(true)
    end

    local default_config = {
        capabilities = make_capabilities(),
    }
    vim.lsp.config('*', default_config)
end

return M
