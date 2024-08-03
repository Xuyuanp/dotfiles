if not vim.fn.has('nvim-0.10') then
    vim.notify('require nvim >= 0.10', vim.log.levels.WARN)
    return
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.mappings').setup()
require('dotvim.autocmds').setup()
require('dotvim.commands').setup()
