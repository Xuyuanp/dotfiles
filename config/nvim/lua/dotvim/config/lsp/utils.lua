-- mostly copied from lazy vim
local group_id = vim.api.nvim_create_augroup('dotvim.config.lsp.utils', { clear = true })

local M = {}

---@type table<string, table<string, table<number, boolean>>>
M._supports_method = {}

---@private
function M._hack_register_capability()
    local method = vim.lsp.protocol.Methods.client_registerCapability
    local register_capability = vim.lsp.handlers[method]
    vim.lsp.handlers[method] = function(err, res, ctx)
        local ret = register_capability(err, res, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client then
            return ret
        end

        for bufnr in ipairs(client.attached_buffers) do
            vim.api.nvim_exec_autocmds('User', {
                pattern = 'DotVimLspDynamicCapability',
                data = { client_id = client.id, buffer = bufnr },
            })
        end

        return ret
    end

    return register_capability
end

---@param client vim.lsp.Client
---@param bufnr number
function M._check_methods(client, bufnr)
    -- don't trigger on invalid buffers
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end
    -- don't trigger on non-listed buffers
    if not vim.bo[bufnr].buflisted then
        return
    end
    -- don't trigger on nofile buffers
    if vim.bo[bufnr].buftype == 'nofile' then
        return
    end
    for method, clients in pairs(M._supports_method) do
        clients[client.name] = clients[client.name] or {}
        if not clients[client.name][bufnr] and client:supports_method(method, bufnr) then
            clients[client.name][bufnr] = true
            vim.api.nvim_exec_autocmds('User', {
                pattern = 'DotVimLspSupportsMethod',
                data = { client_id = client.id, buffer = bufnr, method = method },
            })
        end
    end
end

---@param on_attach OnAttachFunc
---@param opts? {name?:string, desc?:string}
function M.on_attach(on_attach, opts)
    opts = opts or {}
    return vim.api.nvim_create_autocmd('LspAttach', {
        group = group_id,
        desc = opts.desc,
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client and (not opts.name or client.name == opts.name) then
                return on_attach(client, bufnr)
            end
        end,
    })
end

---@param fn OnAttachFunc
---@param opts? {name?:string, desc?:string}
function M.on_dynamic_capability(fn, opts)
    opts = opts or {}
    return vim.api.nvim_create_autocmd('User', {
        pattern = 'DotVimLspDynamicCapability',
        group = group_id,
        desc = opts.desc,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            local bufnr = args.data.buffer ---@type number
            if client and (not opts.name or client.name == opts.name) then
                return fn(client, bufnr)
            end
        end,
    })
end

---@param method string
---@param fn OnAttachFunc
---@param opts? {name?:string, desc?:string}
function M.on_supports_method(method, fn, opts)
    M._supports_method[method] = M._supports_method[method] or setmetatable({}, { __mode = 'k' })
    opts = opts or {}
    return vim.api.nvim_create_autocmd('User', {
        pattern = 'DotVimLspSupportsMethod',
        group = group_id,
        desc = opts.desc,
        callback = function(args)
            if args.data.method ~= method then
                return
            end
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            local bufnr = args.data.buffer ---@type number
            if client and (not opts.name or client.name == opts.name) then
                return fn(client, bufnr)
            end
        end,
    })
end

function M.setup()
    M._hack_register_capability()
    M.on_attach(M._check_methods)
    M.on_dynamic_capability(M._check_methods)
end

return M
