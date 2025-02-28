---@class dotvim.config.blink.inline.Opts
---@field transform? fun(item: blink.cmp.CompletionItem, ctx: blink.cmp.Context, client_id: integer): blink.cmp.CompletionItem
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
    transform = function(item, _ctx, client_id)
        item.client_id = client_id
        local client = vim.lsp.get_client_by_id(client_id)
        if client and client.name == 'copilot-ls' then
            item.kind_name = 'Copilot'
            item.kind_icon = ''
        end
        return item
    end,
    new_params = function(client, _bufnr, params)
        if client.name == 'copilot-ls' then
            params.formattingOptions = {
                tabSize = vim.fn.shiftwidth(),
                insertSpaces = vim.o.expandtab,
            }
        end
        return params
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
    local method = vim.lsp.protocol.Methods.textDocument_inlineCompletion
    local clients = vim.lsp.get_clients({ bufnr = ctx.bufnr, method = method })
    if not clients or not next(clients) then
        callback({
            items = {},
            is_incomplete_forward = false,
            is_incomplete_backward = false,
        })
        return
    end

    local ft = vim.bo[ctx.bufnr].filetype

    ---@param item lsp.InlineCompletionItem
    ---@return blink.cmp.CompletionItem
    local function format_item(item)
        local kind, label
        local text = item.insertText
        if type(text) == 'string' then
            kind = vim.lsp.protocol.CompletionItemKind.Text
        else
            text = text.value
            kind = vim.lsp.protocol.CompletionItemKind.Snippet
        end
        label = vim.trim(text)
        local documentation = string.format('```%s\n%s\n```\n', ft, label)
        return {
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

    ---@type lsp.MultiHandler
    local function handler(responses)
        local items = {}
        vim.iter(pairs(responses or {}))
            :filter(function(_client_id, rsp)
                return not rsp.err and rsp.result
            end)
            :each(function(client_id, rsp)
                ---@type lsp.InlineCompletionItem[]|lsp.InlineCompletionList
                local res = rsp.result
                local inline_item = (vim.islist(res) and res or res.items)[1]
                if not inline_item then
                    return
                end
                local item = format_item(inline_item)
                if self.opts.transform then
                    item = self.opts.transform(item, ctx, client_id)
                end
                table.insert(items, item)
            end)

        callback({
            items = items,
            is_incomplete_forward = false,
            is_incomplete_backward = false,
        })
    end

    local triggerKind = ctx.trigger.kind == 'Invoked' and TriggerKind.Invoked or TriggerKind.Automatic

    local new_params = function(client, bufnr)
        local params = vim.lsp.util.make_position_params(0, client.offset_encoding) --[[@as lsp.InlineCompletionParams]]
        params.context = { triggerKind = triggerKind }
        return self.opts.new_params(client, bufnr, params)
    end
    local cancel = vim.lsp.buf_request_all(ctx.bufnr, method, new_params, handler)
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
