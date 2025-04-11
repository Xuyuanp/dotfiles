---@type vim.lsp.Config
return {
    cmd = function(dispatchers)
        local server = require('nes.server').new(dispatchers)
        return server:new_public_client()
    end,
    capabilities = {
        workspace = { workspaceFolders = true },
    },
}
