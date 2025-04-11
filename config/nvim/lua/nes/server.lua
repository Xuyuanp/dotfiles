local Methods = vim.lsp.protocol.Methods

---@alias nes.MethodHandler fun(server:nes.Server, params: any, callback: fun(err: lsp.ResponseError?, result: any), notify_reply_callback?: fun(message_id: integer)): boolean, integer?

---@class nes.Server
---@field dispatchers vim.lsp.rpc.Dispatchers
---@field private _next_message_id integer
---@field private _handlers table<string, nes.MethodHandler>
local Server = {}
Server.__index = Server

---@param dispatchers vim.lsp.rpc.Dispatchers
---@return nes.Server
function Server.new(dispatchers)
    local self = setmetatable({
        dispatchers = dispatchers,
        _next_message_id = 1,
        _handlers = {
            [Methods.initialize] = Server.on_initialize,
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

--- Sends a request to the LSP server and runs {callback} upon response.
---
---@param method (string) The invoked LSP method
---@param params (table?) Parameters for the invoked LSP method
---@param callback fun(err: lsp.ResponseError?, result: any) Callback to invoke
---@param notify_reply_callback? fun(message_id: integer) Callback to invoke as soon as a request is no longer pending
---@return boolean success `true` if request could be sent, `false` if not
---@return integer? message_id if request could be sent, `nil` if not
function Server:request(method, params, callback, notify_reply_callback)
    callback = callback or function() end
    notify_reply_callback = notify_reply_callback or function() end

    local handler = self._handlers[method]
    if not handler then
        vim.notify('No handler for method: ' .. method, vim.log.levels.WARN)
        return false, nil
    end
    return handler(self, params, callback, notify_reply_callback)
end

--- Receives a notification from the LSP client.
---@param method (string) The invoked LSP method
---@param params (table?) Parameters for the invoked LSP method
---@return boolean `true` if notification could be sent, `false` if not
function Server:notify(method, params)
    method = method
    params = params
    vim.notify(vim.inspect(params), vim.log.levels.INFO, { title = method })
    -- TODO
    return true
end

---@return boolean
function Server:is_closing()
    return false
end

function Server:terminate()
    -- TODO
end

function Server:next_message_id()
    local id = self._next_message_id
    self._next_message_id = self._next_message_id + 1
    return id
end

---@param params lsp.InitializeParams
---@param callback fun(err: lsp.ResponseError?, result: lsp.InitializeResult)
---@param notify_reply_callback? fun(message_id: integer) Callback to invoke as soon as a request is no longer pending
---@return boolean success `true` if request could be sent, `false` if not
---@return integer? message_id if request could be sent, `nil` if not
function Server:on_initialize(params, callback, notify_reply_callback)
    vim.notify(vim.inspect(params), vim.log.levels.INFO, { title = 'on_initialize' })
    local message_id = self:next_message_id()

    vim.schedule(function()
        callback(nil, {
            capabilities = {
                textDocumentSync = {
                    openClose = true,
                    change = 1,
                    save = true,
                },
                workspace = {
                    workspaceFolders = {
                        supported = true,
                        changeNotifications = true,
                    },
                },
            },
            serverInfo = {
                name = 'nes',
                version = '0.1.0',
            },
        })
        if notify_reply_callback then
            notify_reply_callback(message_id)
        end

        vim.schedule(function()
            self.dispatchers.notification(Methods.initialized, vim.empty_dict())
        end)
    end)
    return true, message_id
end

return Server
