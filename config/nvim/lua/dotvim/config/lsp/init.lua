local vim = vim
local api = vim.api

local handlers = require('dotvim.config.lsp.handlers')

local mason_lspcfg = vim.F.npcall(require, 'mason-lspconfig')
if not mason_lspcfg then
    vim.notify_once('mason not installed', vim.log.levels.WARN)
    return
end
local lspconfig = require('lspconfig')

local nlspsettings = vim.F.npcall(require, 'nlspsettings')
if nlspsettings then
    nlspsettings.setup({
        config_home = vim.fn.stdpath('config') .. '/nlsp-settings',
        local_settings_dir = '.nlsp-settings',
        local_settings_root_markers = { '.git' },
        append_default_schemas = true,
        loader = 'json',
    })
end

--- copy from https://github.com/williamboman/nvim-config/blob/main/lua/wb/lsp/on-attach.lua
local function find_and_run_codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lenses = vim.lsp.codelens.get(bufnr)

    lenses = vim.tbl_filter(function(lense)
        return lense.range.start.line < row
    end, lenses)

    if #lenses == 0 then
        return vim.api.nvim_echo({ { 'Could not find codelens to run.', 'WarningMsg' } }, false, {})
    end

    table.sort(lenses, function(a, b)
        return a.range.start.line > b.range.start.line
    end)

    vim.api.nvim_win_set_cursor(0, { lenses[1].range.start.line + 1, lenses[1].range.start.character })
    vim.lsp.codelens.run()
    vim.api.nvim_win_set_cursor(0, { row, col }) -- restore cursor, TODO: also restore position
end

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function set_lsp_keymaps(client, bufnr)
    local key_opts = { noremap = false, silent = true, buffer = bufnr }
    local set_keymap = vim.keymap.set

    local function show_documentation()
        if client.name == 'taplo' and vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
            require('crates').show_popup()
        else
            vim.lsp.buf.hover()
        end
    end

    -- stylua: ignore
    local keymaps = {
        gd  = vim.lsp.buf.definition,
        K   = show_documentation,
        gi  = vim.lsp.buf.implementation,
        gk  = vim.lsp.buf.signature_help,
        gtd = vim.lsp.buf.type_definition,
        gR  = vim.lsp.buf.references,
        grr = vim.lsp.buf.rename,
        gds = vim.lsp.buf.document_symbol,
        gws = vim.lsp.buf.workspace_symbol,
        gca = vim.lsp.buf.code_action,
        go  = vim.lsp.buf.outgoing_calls,
        gcl = find_and_run_codelens,
    }
    for key, action in pairs(keymaps) do
        set_keymap('n', key, action, key_opts)
    end
end

local function set_lsp_autocmd(client, bufnr)
    -- if client.supports_method('textDocument/formatting') then
    --     api.nvim_create_autocmd({ 'BufWritePre' }, {
    --         group = group_id,
    --         buffer = bufnr,
    --         desc = '[lsp] formatting',
    --         callback = function()
    --             if not vim.b[bufnr].lsp_disable_auto_format then
    --                 vim.lsp.buf.format({ async = false })
    --             end
    --         end,
    --     })
    -- end

    if client.supports_method('textDocument/documentHighlight') and client.name ~= 'rust_analyzer' then
        api.nvim_create_autocmd({ 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] document highlight',
            callback = function()
                vim.lsp.buf.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] document highlight clear',
            callback = function()
                vim.lsp.buf.clear_references()
            end,
        })
    end

    if client.supports_method('textDocument/codeLens') then
        api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] code lens',
            callback = vim.lsp.codelens.refresh,
        })
        vim.schedule(vim.lsp.codelens.refresh)
    end
end

local on_attach = function(client, bufnr)
    set_lsp_autocmd(client, bufnr)
    set_lsp_keymaps(client, bufnr)

    vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
    vim.api.nvim_buf_set_option(bufnr, 'tagfunc', 'v:lua.vim.lsp.tagfunc')
end

local default_capabilities = vim.lsp.protocol.make_client_capabilities()

local cmp_lsp = vim.F.npcall(require, 'cmp_nvim_lsp')
if cmp_lsp then
    default_capabilities = cmp_lsp.default_capabilities(default_capabilities)
end

-- stylua: ignore
local default_config = {
    on_attach = on_attach,
    capabilities = default_capabilities,
    handlers = {
        ['workspace/symbol']            = handlers.symbol_handler,
        ['textDocument/references']     = handlers.references,
        ['textDocument/documentSymbol'] = handlers.symbol_handler,
        ['textDocument/definition']     = handlers.gen_location_handler('Definition'),
        ['textDocument/typeDefinition'] = handlers.gen_location_handler('TypeDefinition'),
        ['textDocument/implementation'] = handlers.gen_location_handler('Implementation'),
        ['callHierarchy/outgoingCalls'] = handlers.outgoing_calls,
    },
}

local langs = {
    gopls = {
        filetypes = { 'go', 'gomod', 'gotmpl', 'helm' },
        settings = {
            gopls = {
                usePlaceholders = false,
                gofumpt = true,
                templateExtensions = { 'tpl', 'yaml' },
                codelenses = {
                    generate = true,
                    test = true,
                    tidy = true,
                    upgrade_dependency = true,
                },
                analyses = {
                    fieldaligment = true,
                    nilness = true,
                    shadow = true,
                    unusedwrite = true,
                },
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    },
    rust_analyzer = {
        settings = {
            ['rust-analyzer'] = {
                diagnostics = {
                    enable = true,
                    disabled = { 'unresolved-proc-macro' },
                    enableExperimental = true,
                },
            },
        },
    },
    lua_ls = {
        settings = {
            -- https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json
            Lua = {
                codelenses = {
                    enable = true,
                },
                hint = {
                    enable = true,
                },
                diagnostics = {
                    enable = true,
                    globals = {
                        'vim',
                        'pprint',
                    },
                    disable = {
                        'unused-vararg',
                        'redefined-local',
                    },
                },
                workspace = {
                    checkThirdParty = false,
                },
            },
        },
    },
    sourcery = {
        init_options = {
            token = vim.env.SOURCERY_TOKEN,
        },
    },
    sqls = {
        root_dir = lspconfig.util.root_pattern('.nlsp-settings/sqls.json'),
    },
}

mason_lspcfg.setup_handlers({
    function(server_name)
        local cfg = default_config
        if langs[server_name] then
            cfg = vim.tbl_deep_extend('force', cfg, langs[server_name])
        end
        if server_name == 'rust_analyzer' then
            require('dotvim.config.lsp.rust').setup(cfg)
        else
            lspconfig[server_name].setup(cfg)
        end
    end,
})
