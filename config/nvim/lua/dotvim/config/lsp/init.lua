local vim = vim
local api = vim.api

local a = require('dotvim.util.async')

local LspMethods = vim.lsp.protocol.Methods

local handlers = require('dotvim.config.lsp.handlers')

local lspconfig = require('lspconfig')

local has_nvim_010 = vim.fn.has('nvim-0.10') == 1

--- copy from https://github.com/williamboman/nvim-config/blob/main/lua/wb/lsp/on-attach.lua
local function find_and_run_codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lenses = vim.lsp.codelens.get(bufnr)

    lenses = vim.tbl_filter(function(lense)
        return lense.range.start.line < row
    end, lenses)

    if #lenses == 0 then
        vim.notify('Could not find codelens to run.', vim.log.levels.WARN)
        return
    end

    table.sort(lenses, function(a, b)
        return a.range.start.line > b.range.start.line
    end)

    vim.api.nvim_win_set_cursor(0, { lenses[1].range.start.line + 1, lenses[1].range.start.character })
    vim.lsp.codelens.run()
    vim.api.nvim_win_set_cursor(0, { row, col }) -- restore cursor, TODO: also restore position
end

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function my_show_documentation()
    local clients = vim.lsp.get_clients({ name = 'taplo' })
    if clients and vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
        require('crates').show_popup()
    else
        vim.lsp.buf.hover()
    end
end

local function set_lsp_keymaps(_, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        gd  = { vim.lsp.buf.definition, 'goto definition' },
        K   = { my_show_documentation, 'show documentation' },
        gi  = { vim.lsp.buf.implementation, 'goto implementation' },
        gk  = { vim.lsp.buf.signature_help, 'show signature help' },
        gtd = { vim.lsp.buf.type_definition, 'goto type definition' },
        gR  = { vim.lsp.buf.references, 'show references' },
        grr = { vim.lsp.buf.rename, 'rename' },
        gds = { vim.lsp.buf.document_symbol, 'show document symbols' },
        gws = { vim.lsp.buf.workspace_symbol, 'show workspace symbols' },
        gca = { vim.lsp.buf.code_action, 'code action' },
        go  = { vim.lsp.buf.outgoing_calls, 'show outgoing calls' },
        gcl = { find_and_run_codelens, 'find and run codelens' },
    }
    for key, action in pairs(keymaps) do
        set_keymap('n', key, action[1], {
            noremap = false,
            silent = true,
            buffer = bufnr,
            desc = '[Lsp] ' .. action[2],
        })
    end

    local show_menu = a.wrap(function()
        local choice = a.ui
            .select(vim.tbl_values(keymaps), {
                prompt = 'Lsp actions:',
                format_item = function(item)
                    -- uppercase the first letter
                    local display = item[2]:gsub('^%l', string.upper)
                    return display
                end,
            })
            .await()
        if choice then
            choice[1]()
        end
    end)

    set_keymap('n', '<space><space>', show_menu, {
        noremap = false,
        silent = true,
        buffer = bufnr,
        desc = '[Lsp] show menu',
    })
end

local function set_lsp_autocmd(client, bufnr)
    if client.supports_method(LspMethods.textDocument_documentHighlight) and client.name ~= 'rust_analyzer' then
        api.nvim_create_autocmd({ 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[Lsp] document highlight',
            callback = function()
                vim.lsp.buf.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[Lsp] document highlight clear',
            callback = function()
                vim.lsp.buf.clear_references()
            end,
        })
    end

    if client.supports_method(LspMethods.textDocument_codeLens) then
        api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] codelens refresh',
            callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
        })
        vim.schedule(function()
            vim.lsp.codelens.refresh({ bufnr = bufnr })
        end)
    end
end

local function on_attach_nvim_010(client, bufnr)
    if client.supports_method(LspMethods.textDocument_inlayHint) then
        vim.schedule(function()
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end)
    end
end

local on_attach = function(client, bufnr)
    set_lsp_autocmd(client, bufnr)
    set_lsp_keymaps(client, bufnr)

    if has_nvim_010 then
        on_attach_nvim_010(client, bufnr)
    end

    if vim.bo[bufnr].filetype == 'helm' and client.name == 'gopls' then
        vim.defer_fn(function()
            vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end, 100)
    end

    vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr()'
    vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
    vim.bo[bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
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
        [LspMethods.workspace_symbol]            = handlers.symbol_handler,
        [LspMethods.textDocument_references]     = handlers.references,
        [LspMethods.textDocument_documentSymbol] = handlers.symbol_handler,
        [LspMethods.textDocument_definition]     = handlers.gen_location_handler('Definition'),
        [LspMethods.textDocument_typeDefinition] = handlers.gen_location_handler('TypeDefinition'),
        [LspMethods.textDocument_implementation] = handlers.gen_location_handler('Implementation'),
        [LspMethods.callHierarchy_outgoingCalls] = handlers.outgoing_calls,
    },
}

local function make_on_new_config(opts)
    opts = opts or {}
    return function(new_config)
        local on_attach_origin = new_config.on_attach or function() end
        new_config.on_attach = function(client, ...)
            if opts.disable_hover then
                client.server_capabilities.hoverProvider = false
            end
            on_attach_origin(client, ...)
        end
    end
end

local langs = {
    gopls = {
        filetypes = { 'go', 'gomod', 'gotmpl', 'helm' },
        settings = {
            gopls = {
                usePlaceholders = false,
                templateExtensions = { 'tpl', 'yaml' },
                experimentalPostfixCompletions = true,
                semanticTokens = true,
                staticcheck = true,
                vulncheck = 'Imports',
                codelenses = {
                    gc_details = true,
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
                    unusedparams = true,
                    unusedvariable = true,
                    useany = true,
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
    sqls = {
        root_dir = lspconfig.util.root_pattern('.nlsp-settings/sqls.json'),
    },
    sourcery = {
        on_new_config = make_on_new_config({ disable_hover = true }),
    },
    ruff_lsp = {
        on_new_config = make_on_new_config({ disable_hover = true }),
    },
    clangd = {
        -- disable clangd for proto files
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
        capabilities = {
            -- suppress warning: multiple different client offset_encodings detected for buffer, this is not supported yet
            -- see: https://github.com/jose-elias-alvarez/null-ls.nvim/issues/428#issuecomment-997226723
            offsetEncoding = { 'utf-16' },
        },
    },
}

require('mason-lspconfig').setup_handlers({
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
