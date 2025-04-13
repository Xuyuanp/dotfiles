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
        filetypes = { 'go', 'gomod', 'gotmpl' },
        settings = {
            gopls = {
                usePlaceholders = false,
                templateExtensions = { 'tpl', 'yaml' },
                experimentalPostfixCompletions = true,
                semanticTokens = false,
                semanticTokenTypes = {
                    string = false,
                    keyword = false,
                },
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
                    unusedLocalExclude = { '_*', 'self' },
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

    local setup = function(server_name)
        if langs[server_name] then
            vim.lsp.config(server_name, langs[server_name])
        end
        vim.lsp.enable(server_name)
    end

    require('mason-lspconfig').setup_handlers({
        setup,
        ['rust_analyzer'] = function() end,
    })

    vim.lsp.enable('copilot-ls')
end

return M
