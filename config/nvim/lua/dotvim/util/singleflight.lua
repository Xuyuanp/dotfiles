local a = require('dotvim.util.async')

local M = {}

function M.new()
    return setmetatable({
        inflights = {},
    }, { __index = M })
end

function M:run(key, fn)
    if self.inflights[key] then
        return
    end
    self.inflights[key] = true
    a.run(function()
        fn()
        self.inflights[key] = nil
    end)
end

return M
