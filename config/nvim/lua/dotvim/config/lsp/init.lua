---@alias LspClient vim.lsp.Client
---@alias OnAttachFunc fun(client: LspClient, bufnr: number):boolean?

local default_capabilities = require('dotvim.config.lsp.capabilities')

local function make_capabilities()
    if vim.g.dotvim_lsp_capabilities then
        return vim.g.dotvim_lsp_capabilities()
    end
    return default_capabilities
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
                noSemanticString = true,
                -- semanticTokenTypes = {
                --     string = false,
                --     keyword = false,
                -- },
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
                    unusedLocalExclude = { '_*' },
                },
                runtime = {
                    version = 'LuaJIT',
                },
            },
        },
    },
    clangd = {
        -- disable clangd for proto files
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    },
}

local M = {}

function M.setup()
    require('dotvim.config.lsp.buf').overwrite()
    require('dotvim.config.lsp.utils').setup()
    require('dotvim.config.lsp.keymaps').setup()
    require('dotvim.config.lsp.autocmds').setup()

    local default_config = {
        capabilities = make_capabilities(),
    }
    vim.lsp.config('*', default_config)

    local native_setup = function(server_name)
        local cfg = vim.tbl_deep_extend('force', require('lspconfig.configs.' .. server_name).default_config, langs[server_name] or {})
        vim.lsp.config(server_name, cfg)
        vim.lsp.enable(server_name)
    end
    local oldstyle_setup = function(server_name)
        local lspconfig = require('lspconfig')
        local cfg = vim.tbl_deep_extend('force', default_config, langs[server_name] or {})
        lspconfig[server_name].setup(cfg)
    end

    local use_native = false
    local setup = use_native and native_setup or oldstyle_setup

    require('mason-lspconfig').setup_handlers({
        setup,
        ['rust_analyzer'] = function() end,
    })
end

return M
