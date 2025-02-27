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

---@param client vim.lsp.Client
---@param ctx lsp.HandlerContext
local function sign_in(client, ctx)
    local method = 'signIn'

    for _, req in pairs(client.requests) do
        if req.type == 'pending' and req.method == method then
            return
        end
    end

    local bufnr = ctx.bufnr

    client:request(method, vim.empty_dict(), function(err, res)
        assert(not err, err)
        vim.print(res.userCode)
        client:exec_cmd(res.command, { bufnr = bufnr }, function(err, res)
            assert(not err, err)
            local __res_example = {
                status = 'OK',
                user = '<username>',
            }

            vim.print(res)
        end)
    end)
end

---@type table<string, lsp.Handler>
local handlers = {
    didChangeStatus = function(_err, params, ctx)
        local __params_example = {
            busy = false,
            kind = 'Error',
            message = 'You are not signed into GitHub. Please sign in to use Copilot.',
        }

        if params.busy then
            return
        end

        if params.kind == 'Normal' and not params.message then
            return
        end

        if params.kind == 'Error' and params.message:find('not signed') then
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if not client then
                return
            end
            sign_in(client, ctx)
            return
        end

        notify(params.message, KindToLevel[params.kind])
    end,
    featureFlagsNotification = function(_err, params, _ctx)
        if not params or not params.ic then
            notify_once('Inline completion is disabled', vim.log.levels.WARN)
            return
        end
    end,
}

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
}
