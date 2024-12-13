local lspconfig = require('lspconfig')

local default_config = require('dotvim.config.lsp.utils')

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
                    disable = {
                        'unused-vararg',
                        'redefined-local',
                    },
                    globals = {
                        'vim',
                        'require',
                        'assert',
                        'print',
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

local function setup()
    require('mason-lspconfig').setup_handlers({
        function(server_name)
            local cfg = {
                capabilities = default_config.capabilities,
                handlers = default_config.handlers,
            }
            if langs[server_name] then
                cfg = vim.tbl_deep_extend('force', cfg, langs[server_name])
            end
            if server_name == 'rust_analyzer' then
            -- require('dotvim.config.lsp.rust').setup(cfg)
            else
                lspconfig[server_name].setup(cfg)
            end
        end,
    })
    -- suppress warning: bufls deprecated
    -- TODO: remove this after bufls is removed
    lspconfig['buf_ls'].setup({
        capabilities = default_config.capabilities,
        handlers = default_config.handlers,
    })

    local group_id = vim.api.nvim_create_augroup('dotvim_lsp_init', { clear = true })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = group_id,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            assert(client, 'client not found')
            default_config.on_attach(client, args.buf)
        end,
    })

    vim.api.nvim_create_autocmd('BufWritePre', {
        group = group_id,
        desc = '[Lsp] format on save',
        callback = function(args)
            local bufnr = args.buf
            ---@param client Client client passed here supports textDocument_formatting
            local filter = function(client)
                if client.name == 'null-ls' then
                    return true
                end
                if vim.b[bufnr].lsp_disable_auto_format then
                    return false
                end
                return true
            end
            require('dotvim.config.lsp.my').format({
                bufnr = bufnr,
                async = false,
                filter = filter,
            })
        end,
    })
end

local M = {
    setup = setup,
}

return M
