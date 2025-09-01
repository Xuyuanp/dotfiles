-- https://github.com/orgs/github/packages/npm/package/copilot-language-server

local KindToLevel = {
    Normal = vim.log.levels.INFO,
    Error = vim.log.levels.ERROR,
    Warning = vim.log.levels.WARN,
    Inactive = vim.log.levels.WARN,
}

local function notify(msg, level, opts)
    opts = opts or {}
    opts.title = 'copilot'
    vim.notify(msg, level, opts)
end

local function notify_once(msg, level, opts)
    opts = opts or {}
    opts.title = 'copilot'
    vim.notify_once(msg, level, opts)
end

local methods = {
    signIn = 'signIn',
    textDocument_didFocus = 'textDocument/didFocus',
}

---@param client_id integer
---@param bufnr integer
local function sign_in(client_id, bufnr)
    local client = vim.lsp.get_client_by_id(client_id)
    if not client then
        return
    end
    for _, req in pairs(client.requests) do
        if req.type == 'pending' and req.method == methods.signIn then
            return
        end
    end
    client:request(methods.signIn, vim.empty_dict(), nil, bufnr)
end

---@type table<string, lsp.Handler>
local handlers = {
    ---@param res {busy: boolean, kind: 'Normal'|'Error'|'Warning'|'Inactive', message: string}
    didChangeStatus = function(_err, res, ctx)
        if res.busy then
            return
        end

        if res.kind == 'Normal' and not res.message then
            return
        end

        -- message: You are not signed into GitHub. Please sign in to use Copilot.
        if res.kind == 'Error' and res.message:find('not signed into') then
            sign_in(ctx.client_id, ctx.bufnr)
            return
        end

        notify(res.message, KindToLevel[res.kind])
    end,

    ---@param res {ic: boolean}
    featureFlagsNotification = function(_err, res, _ctx)
        if not res or not res.ic then
            notify_once('Inline completion is disabled', vim.log.levels.WARN)
            return
        end
    end,

    ---@param res {command: lsp.Command, userCode: string, verificationUri: string}
    signIn = function(err, res, ctx)
        if err then
            notify('Failed to sign in: ' .. vim.inspect(err), vim.log.levels.ERROR)
            return
        end

        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then
            return
        end

        vim.fn.setreg('+', res.userCode)
        vim.fn.setreg('*', res.userCode)

        vim.print(string.format(
            [[If browser does not open automatically, please visit: %s
Enter the code: %s]],
            res.verificationUri,
            res.userCode
        ))

        client:exec_cmd(res.command, { bufnr = ctx.bufnr }, function(cmd_err, cmd_res)
            if cmd_err then
                notify('Failed to open browser: ' .. vim.inspect(cmd_err), vim.log.levels.WARN)
                return
            end
            if cmd_res.status == 'OK' then
                notify('Successfully signed in as: ' .. cmd_res.user, vim.log.levels.INFO)
            else
                notify('Failed to sign in: ' .. vim.inspect(cmd_res), vim.log.levels.ERROR)
            end
        end)
    end,
}

---@type vim.lsp.Config
return {
    root_markers = { '.git', 'lua/' },
    capabilities = {
        workspace = { workspaceFolders = true },
    },
    handlers = handlers,
    on_init = function(client)
        local group = vim.api.nvim_create_augroup('dotvim.lsp.copilot', { clear = true })
        vim.api.nvim_create_autocmd('BufWinEnter', {
            group = group,
            callback = function(args)
                local params = vim.lsp.util.make_text_document_params(args.buf)
                client:notify(methods.textDocument_didFocus, params)
            end,
        })
    end,
}
