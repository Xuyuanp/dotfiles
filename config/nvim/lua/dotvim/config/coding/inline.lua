---@class dotvim.config.blink.inline.Opts
---@field transform? fun(item: blink.cmp.CompletionItem, cmp_ctx: blink.cmp.Context, lsp_ctx: lsp.HandlerContext): blink.cmp.CompletionItem
---@field new_params? fun(client: vim.lsp.Client, bufnr: integer, params: table): table

---@module 'blink.cmp'
---@class dotvim.config.blink.inline.Source : blink.cmp.Source
---@field opts dotvim.config.blink.inline.Opts
local source = {}

local TriggerKind = {
    Invoked = 1,
    Automatic = 2,
}

local default_opts = {
    transform = function(item, _cmp_ctx, _lsp_ctx)
        if item.client_name == 'copilot-ls' then
            item.kind_name = 'Copilot'
            item.kind_icon = ''
        end
        return item
    end,
    new_params = function(client, bufnr, params)
        if client.name == 'copilot-ls' then
            params.textDocument.version = vim.lsp.util.buf_versions[bufnr]
            params.formattingOptions = {
                tabSize = vim.fn.shiftwidth(),
                insertSpaces = vim.o.expandtab,
            }
        end
        return params
    end,
}

local function gen_cancel(pending)
    return function()
        for client_id, request_id in pairs(pending) do
            local client = vim.lsp.get_client_by_id(client_id)
            if client and client.requests[request_id] and client.requests[request_id].type == 'pending' then
                client:cancel_request(request_id)
            end
        end
    end
end

---@param opts dotvim.config.blink.inline.Opts
function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = vim.tbl_deep_extend('force', default_opts, opts)
    return self
end

function source:get_trigger_characters()
    return { '.' }
end
---@param item lsp.InlineCompletionItem
---@param context lsp.HandlerContext
---@return blink.cmp.CompletionItem
local function format_item(item, context)
    local kind, label
    local text = item.insertText
    if type(text) == 'string' then
        kind = vim.lsp.protocol.CompletionItemKind.Text
    else
        text = text.value
        kind = vim.lsp.protocol.CompletionItemKind.Snippet
    end
    label = vim.trim(text)
    local documentation = string.format('```%s\n%s\n```\n', vim.bo[context.bufnr].filetype, label)
    local client = vim.lsp.get_client_by_id(context.client_id)
    return {
        client_id = context.client_id,
        client_name = client and client.name,
        kind = kind,
        label = label,
        documentation = documentation,
        -- convert to traditional TextEdit
        textEdit = {
            newText = item.insertText,
            range = item.range,
        },
        command = item.command,
    }
end

---@param handler lsp.Handler
---@param remaining integer
---@param done fun()
---@return lsp.Handler
local function wrap_handler(handler, remaining, done)
    return function(err, res, context, config)
        handler(err, res, context, config)
        remaining = remaining - 1
        if remaining == 0 then
            done()
        end
    end
end

---@param ctx blink.cmp.Context
---@param callback fun(blink.cmp.CompletionResponse?): (fun()|nil)
function source:get_completions(ctx, callback)
    local final = {
        items = {},
        is_incomplete_forward = false,
        is_incomplete_backward = false,
    }

    local method = vim.lsp.protocol.Methods.textDocument_inlineCompletion
    local clients = vim.lsp.get_clients({ bufnr = ctx.bufnr, method = method })
    if #clients == 0 then
        callback(final)
        return
    end

    ---@param err lsp.ResponseError?
    ---@param res lsp.InlineCompletionItem[]|lsp.InlineCompletionList
    ---@param context lsp.HandlerContext
    local function on_result(err, res, context)
        if err then
            return
        end
        local inline_item = (vim.islist(res) and res or res.items)[1]
        if not inline_item then
            return
        end
        local item = format_item(inline_item, context)
        if self.opts.transform then
            item = self.opts.transform(item, ctx, context)
        end
        table.insert(final.items, item)
    end

    local handler = wrap_handler(on_result, #clients, function()
        callback(final)
    end)

    local triggerKind = ctx.trigger.kind == 'Invoked' and TriggerKind.Invoked or TriggerKind.Automatic
    local new_params = function(client, bufnr)
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding) --[[@as lsp.InlineCompletionParams]]
        params.context = {
            triggerKind = triggerKind,
            selectedCompletionInfo = nil,
        }
        return self.opts.new_params(client, bufnr, params)
    end

    local pending, _cancel = vim.lsp.buf_request(ctx.bufnr, method, new_params, handler)
    if #pending == 0 then
        callback(final)
        return
    end
    return gen_cancel(pending)
end

function source:execute(ctx, item, callback, default)
    default()
    local client = vim.lsp.get_client_by_id(item.client_id)
    if client and item.command then
        client:exec_cmd(item.command, { bufnr = ctx.bufnr }, function()
            callback()
        end)
    else
        callback()
    end
end

return source
