local min_version = '0.12'
if not vim.fn.has('nvim-' .. min_version) then
    vim.notify('require nvim >= ' .. min_version, vim.log.levels.WARN)
    return
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.autocmds').setup()
require('dotvim.commands').setup()
require('dotvim.config.lsp').setup()

if vim.g.neovide then
    require('dotvim.neovide').setup()
end
