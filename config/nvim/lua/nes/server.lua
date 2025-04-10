local Methods = vim.lsp.protocol.Methods

local function notify(text, opts)
    opts = opts or {}
    opts.title = '[NES] ' .. (opts.title or '')
    opts.level = opts.level or vim.log.levels.INFO
    vim.notify(text, opts.level, { title = opts.title })
end

---@alias nes.MethodHandler fun(server:nes.Server, params: any): lsp.ResponseError, any

---@class nes.Server
---@field dispatchers vim.lsp.rpc.Dispatchers
---@field private _next_message_id integer
---@field private _handlers table<string, nes.MethodHandler>
local Server = {}
Server.__index = Server

local capabilities = {
    textDocumentSync = 2,
    --     openClose = true,
    --     change = 2,
    --     save = true,
    -- },
    workspace = {
        workspaceFolders = {
            supported = true,
            changeNotifications = true,
        },
    },
}

---@param dispatchers vim.lsp.rpc.Dispatchers
---@return nes.Server
function Server.new(dispatchers)
    local self = setmetatable({
        dispatchers = dispatchers,
        _next_message_id = 1,
        _handlers = {
            [Methods.initialize] = Server.on_initialize,
            [Methods.initialized] = Server.on_initialized,
            [Methods.textDocument_didOpen] = Server.on_did_open,
            [Methods.textDocument_didSave] = Server.on_did_save,
            [Methods.textDocument_didChange] = Server.on_did_change,
        },
    }, Server)
    return self
end

---@return vim.lsp.rpc.PublicClient
function Server:new_public_client()
    return {
        request = function(...)
            return self:request(...)
        end,
        notify = function(...)
            return self:notify(...)
        end,
        is_closing = function()
            return self:is_closing()
        end,
        terminate = function()
            self:terminate()
        end,
    }
end

--- Receives a request from the LSP client
---
---@param method vim.lsp.protocol.Method | string The invoked LSP method
---@param params table? Parameters for the invoked LSP method
---@param callback fun(err: lsp.ResponseError?, result: any) Callback to invoke
---@param notify_reply_callback? fun(message_id: integer) Callback to invoke as soon as a request is no longer pending
---@return boolean success `true` if request could be sent, `false` if not
---@return integer? message_id if request could be sent, `nil` if not
function Server:request(method, params, callback, notify_reply_callback)
    notify_reply_callback = notify_reply_callback or function() end

    local handler = self._handlers[method]
    if not handler then
        vim.notify('No handler for method: ' .. method, vim.log.levels.WARN)
        return false, nil
    end
    local message_id = self:new_message_id()

    vim.schedule(function()
        local err, result = handler(self, params)
        callback(err, result)
        if not err then
            notify_reply_callback(message_id)
        end
    end)
    return true, message_id
end

--- Receives a notification from the LSP client.
---@param method string The invoked LSP method
---@param params table? Parameters for the invoked LSP method
---@return boolean
function Server:notify(method, params)
    method = method
    params = params
    local handler = self._handlers[method]
    if not handler then
        vim.notify('No handler for method: ' .. method, vim.log.levels.WARN)
        return false
    end
    vim.schedule(function()
        handler(self, params)
    end)
    return true
end

---@return boolean
function Server:is_closing()
    return false
end

function Server:terminate()
    -- TODO
end

function Server:new_message_id()
    local id = self._next_message_id
    self._next_message_id = self._next_message_id + 1
    return id
end

---@param params lsp.InitializeParams
---@return lsp.ResponseError?
---@return lsp.InitializeResult
function Server:on_initialize(params)
    params = params
    local result = {
        capabilities = capabilities,
        serverInfo = {
            name = 'nes',
            version = '0.1.0',
        },
    }
    vim.schedule(function()
        self.dispatchers.server_request(Methods.window_logMessage, { type = 3, message = 'NES initialized' })
    end)
    return nil, result
end

---@param params lsp.InitializedParams
function Server:on_initialized(params)
    params = params
    self._client_initialized = true
end

---@param params lsp.DidOpenTextDocumentParams
function Server:on_did_open(params)
    params = params
    notify(vim.inspect(params), { title = 'on_did_open' })
end

---@param params lsp.DidSaveTextDocumentParams
function Server:on_did_save(params)
    params = params
    notify(vim.inspect(params), { title = 'on_did_save' })
end

---@param params lsp.DidChangeTextDocumentParams
function Server:on_did_change(params)
    params = params
    notify(vim.inspect(params), { title = 'on_did_change' })
end

return Server
