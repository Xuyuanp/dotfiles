local min_version = '0.11'
if not vim.fn.has('nvim-' .. min_version) then
    vim.notify('require nvim >= ' .. min_version, vim.log.levels.WARN)
    return
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.mappings').setup()
require('dotvim.autocmds').setup()
require('dotvim.commands').setup()
