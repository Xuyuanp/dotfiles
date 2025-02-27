---@class dotvim.config.blink.inline.Opts
---@field transform? fun(item: blink.cmp.CompletionItem, ctx: blink.cmp.Context, client_id: integer): blink.cmp.CompletionItem

---@module 'blink.cmp'
---@class dotvim.config.blink.inline.Source : blink.cmp.Source
---@field opts dotvim.config.blink.inline.Opts
local source = {}

local TriggerKind = {
    Invoked = 1,
    Automatic = 2,
}

local default_opts = {
    transform = function(item, _ctx, client_id)
        item.client_id = client_id
        local client = vim.lsp.get_client_by_id(client_id)
        if client and client.name == 'copilot-ls' then
            item.kind_name = 'Copilot'
            item.kind_icon = ''
        end
        return item
    end,
}

---@param opts dotvim.config.blink.inline.Opts
function source.new(opts)
    local self = setmetatable({}, { __index = source })
    self.opts = vim.tbl_deep_extend('force', default_opts, opts)
    return self
end

function source:get_trigger_characters()
    return { '.' }
end

function source:get_completions(ctx, callback)
    local params = function(client, _bufnr)
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding) --[[@as table]]
        params.context = {
            triggerKind = ctx.trigger.kind == 'Invoked' and TriggerKind.Invoked or TriggerKind.Automatic,
        }
        params.formattingOptions = {
            tabSize = vim.fn.shiftwidth(),
            insertSpaces = vim.o.expandtab,
        }
        return params
    end
    local ft = vim.bo[ctx.bufnr].filetype

    ---@type lsp.MultiHandler
    local function handler(responses)
        local items = {}
        for client_id, rsp in pairs(responses) do
            if not rsp.err and rsp.result and rsp.result.items and #rsp.result.items > 0 then
                local item = rsp.result.items[1]
                item.kind = vim.lsp.protocol.CompletionItemKind.Text
                item.label = vim.trim(item.insertText)
                item.documentation = string.format('```%s\n%s\n```\n', ft, item.label)
                -- convert to traditional TextEdit
                item.textEdit = {
                    newText = item.insertText,
                    range = item.range,
                }

                if self.opts.transform then
                    item = self.opts.transform(item, ctx, client_id)
                end
                table.insert(items, item)
            end
        end

        callback({
            items = items,
            is_incomplete_forward = false,
            is_incomplete_backward = false,
        })
    end
    local cancel = vim.lsp.buf_request_all(ctx.bufnr, vim.lsp.protocol.Methods.textDocument_inlineCompletion, params, handler)
    return cancel
end

function source:execute(ctx, item, callback)
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
