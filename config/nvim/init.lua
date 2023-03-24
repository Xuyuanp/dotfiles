if not vim.fn.has('nvim-0.8') then
    error('require nvim >= 0.8')
end

_G.pprint = function(obj)
    print(vim.inspect(obj))
end

require('dotvim.settings').setup()
require('dotvim.lazy').setup()
require('dotvim.mappings').setup()
require('dotvim.autocmds').setup()

-- force quit
vim.cmd([[command! Q execute('qa!')]])
