if not vim.fn.has('nvim-0.8') then
    error('require nvim >= 0.8')
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.mappings').setup()
require('dotvim.autocmds').setup()

-- force quit
vim.cmd([[command! Q execute('qa!')]])
