local M = {}

return setmetatable(M, {
    __index = function(t, feat)
        local enabled = rawget(t, feat)
        if enabled == nil then
            enabled = vim.env['NVIM_' .. feat:upper() .. '_ENABLED'] == 'true'
            rawset(t, feat, enabled)
        end
        return enabled
    end,
    __newindex = function()
        error('features are read-only')
    end,
})
