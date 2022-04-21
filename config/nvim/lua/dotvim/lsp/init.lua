local vim = vim
local api = vim.api
local vfn = vim.fn

local handlers = require('dotvim.lsp.handlers')

local lsp_status = require('lsp-status')
local lsp_inst = require('nvim-lsp-installer')

lsp_status.register_progress()

local enable_auto_format = vfn['dotvim#lsp#EnableAutoFormat']

local function set_lsp_keymaps(bufnr)
    local key_opts = { noremap = false, silent = true, buffer = bufnr }
    local set_keymap = vim.keymap.set
    local keymaps = {
        gd = vim.lsp.buf.definition,
        K = vim.lsp.buf.hover,
        gi = vim.lsp.buf.implementation,
        gk = vim.lsp.buf.signature_help,
        gtd = vim.lsp.buf.type_definition,
        gR = vim.lsp.buf.references,
        grr = vim.lsp.buf.rename,
        gds = vim.lsp.buf.document_symbol,
        gws = vim.lsp.buf.workspace_symbol,
        gca = vim.lsp.buf.code_action,
        go = vim.lsp.buf.outgoing_calls,

        [']d'] = vim.diagnostic.goto_next,
        ['[d'] = vim.diagnostic.goto_prev,
        ['<leader>sd'] = vim.diagnostic.open_float,
    }
    for key, action in pairs(keymaps) do
        set_keymap('n', key, action, key_opts)
    end
end

local on_attach = function(client, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    lsp_status.on_attach(client)

    local server_capabilities = client.server_capabilities
    if server_capabilities.signatureHelpProvider then
        server_capabilities.signatureHelpProvider.triggerCharacters = { '(', ',', ' ' }
    end

    if server_capabilities.documentFormattingProvider then
        enable_auto_format()
    end

    if server_capabilities.documentHighlightProvider and client.name ~= 'rust_analyzer' then
        local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })
        api.nvim_create_autocmd({ 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.clear_references()
            end,
        })
    end

    set_lsp_keymaps(bufnr)
end

vfn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vfn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vfn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vfn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

local default_capabilities = lsp_status.capabilities

local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if ok then
    default_capabilities = cmp_lsp.update_capabilities(default_capabilities)
end

local default_config = {
    on_attach = on_attach,
    capabilities = default_capabilities,
    handlers = {
        ['textDocument/hover'] = handlers.hover,
        ['workspace/symbol'] = handlers.symbol_handler,
        ['textDocument/references'] = handlers.references,
        ['textDocument/documentSymbol'] = handlers.symbol_handler,
        ['textDocument/codeAction'] = handlers.code_action,
        ['textDocument/definition'] = handlers.gen_location_handler('Definition'),
        ['textDocument/typeDefinition'] = handlers.gen_location_handler('TypeDefinition'),
        ['textDocument/implementation'] = handlers.gen_location_handler('Implementation'),
        ['callHierarchy/outgoingCalls'] = handlers.outgoing_calls,
    },
}

local function detect_lua_library()
    local library = {}

    local cwd = vfn.getcwd()
    local paths = vim.api.nvim_list_runtime_paths()
    for _, path in ipairs(paths) do
        if not vim.startswith(cwd, path) and vfn.isdirectory(path .. '/lua') > 0 then
            library[path] = true
        end
    end

    return library
end

local langs = {
    gopls = {
        settings = {
            gopls = {
                usePlaceholders = false,
            },
        },
    },
    sumneko_lua = {
        root_dir = function(fname)
            -- default is git find_git_ancestor or home dir
            return require('lspconfig.util').find_git_ancestor(fname) or vfn.fnamemodify(fname, ':p:h')
        end,
        settings = {
            -- https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json
            Lua = {
                diagnostics = {
                    enable = true,
                    globals = {
                        'vim',
                        'pprint',
                    },
                    disable = {
                        'unused-vararg',
                        'unused-local',
                        'redefined-local',
                    },
                },
                runtime = {
                    version = 'LuaJIT',
                },
                workspace = {
                    library = detect_lua_library(),
                    ignoreDir = {
                        '.cache',
                    },
                },
            },
        },
    },
}

lsp_inst.on_server_ready(function(server)
    local cfg = default_config
    if langs[server.name] then
        cfg = vim.tbl_deep_extend('force', cfg, langs[server.name])
    end
    if server.name == 'rust_analyzer' then
        local opts = server:get_default_options()
        require('dotvim.lsp.rust').setup(vim.tbl_deep_extend('force', opts, cfg))
    else
        server:setup(cfg)
    end
    vim.cmd([[do User LspAttachBuffers]])
end)
