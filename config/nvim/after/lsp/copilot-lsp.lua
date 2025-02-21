local KindToLevel = {
    Normal = vim.log.levels.INFO,
    Error = vim.log.levels.ERROR,
    Warning = vim.log.levels.WARN,
    Inactive = vim.log.levels.WARN,
}

local function sign_in(client, ctx)
    local method = 'signIn'

    for _, req in pairs(client.requests) do
        if req.type == 'pending' and req.method == method then
            return
        end
    end

    client:request(method, vim.empty_dict(), function(err, res)
        assert(not err, err)
        vim.print(res.userCode)
        client:exec_cmd(res.command, { bufnr = ctx.bufnr }, function(err, res)
            assert(not err, err)
            local __res_example = {
                status = 'OK',
                user = '<username>',
            }

            vim.print(res)
        end)
    end)
end

local handlers = {
    didChangeStatus = function(_, params, ctx)
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
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            sign_in(client, ctx)

            return
        end

        vim.notify(params.message, KindToLevel[params.kind], { title = 'Copilot-lsp' })
    end,
    featureFlagsNotification = function(_err, params, ctx)
        if not params.ic then
            vim.notify_once('Inline completion is disabled', vim.log.levels.WARN, { title = 'Copilot-lsp' })
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            client:stop()
            return
        end
    end,
}

local version = vim.version()

return {
    cmd = { 'copilot-language-server', '--stdio' },
    root_dir = vim.fs.root(0, { '.git' }),
    init_options = {
        editorInfo = {
            name = 'Neovim',
            version = string.format('v%d.%d.%d', version.major, version.minor, version.patch),
        },
        editorPluginInfo = {
            name = 'Copilot-lsp',
            version = '0.1.0',
        },
    },
    handlers = handlers,
}
