---@type table<string, boolean>
local Features = require('dotvim.util').new_cache_table(function(feat)
    return vim.env['NVIM_' .. feat:upper() .. '_ENABLED'] == 'true'
end)

return Features
