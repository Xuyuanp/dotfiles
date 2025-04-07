-- https://github.com/orgs/github/packages/npm/package/copilot-language-server

local KindToLevel = {
    Normal = vim.log.levels.INFO,
    Error = vim.log.levels.ERROR,
    Warning = vim.log.levels.WARN,
    Inactive = vim.log.levels.WARN,
}

local function notify(msg, level, opts)
    opts = opts or {}
    opts.title = 'copilot-ls'
    vim.notify(msg, level, opts)
end

local function notify_once(msg, level, opts)
    opts = opts or {}
    opts.title = 'copilot-ls'
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

        vim.print(string.format(
            [[If browser does not open automatically, please visit: %s
Enter the code: %s]],
            res.verificationUri,
            res.userCode
        ))

        client:exec_cmd(res.command, { bufnr = ctx.bufnr }, function(err, res)
            if err then
                notify('Failed to open browser: ' .. vim.inspect(err), vim.log.levels.WARN)
                return
            end
            if res.status == 'OK' then
                notify('Successfully signed in as: ' .. res.user, vim.log.levels.INFO)
            else
                notify('Failed to sign in: ' .. vim.inspect(res), vim.log.levels.ERROR)
            end
        end)
    end,
}

vim.api.nvim_create_autocmd('BufWinEnter', {
    group = vim.api.nvim_create_augroup('dotvim.lsp.copilot_ls', { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_clients({ bufnr = args.buf, name = 'copilot-ls' })[1]
        if not client then
            return
        end
        local params = vim.lsp.util.make_text_document_params(args.buf)
        client:notify(methods.textDocument_didFocus, params)
    end,
})

local version = vim.version()

---@type vim.lsp.Config
return {
    cmd = { 'copilot-language-server', '--stdio' },
    root_dir = vim.fs.root(0, { '.git', 'lua/' }),
    init_options = {
        editorInfo = {
            name = 'Neovim',
            version = string.format('v%d.%d.%d', version.major, version.minor, version.patch),
        },
        editorPluginInfo = {
            name = 'copilot-ls',
            version = 'dev',
        },
    },
    handlers = handlers,
    capabilities = {
        workspace = { workspaceFolders = true },
    },
}
