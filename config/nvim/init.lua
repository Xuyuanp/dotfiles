if not vim.fn.has('nvim-0.10') then
    error('require nvim >= 0.10')
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.mappings').setup()
require('dotvim.autocmds').setup()
require('dotvim.commands').setup()
