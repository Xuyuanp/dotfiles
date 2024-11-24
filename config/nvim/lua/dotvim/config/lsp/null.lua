local M = {}

---@param client vim.lsp.Client
---@param bufnr number
local function on_lsp_attach(client, bufnr)
    local support_formatting = client:supports_method(vim.lsp.protocol.Methods.textDocument_formatting)
    if not support_formatting then
        return
    end

    local event = 'BufWritePre'
    local desc = 'Formatting on save by lsp ' .. client.name

    if client.name ~= 'null-ls' and vim.b[bufnr].lsp_disable_auto_format then
        -- disable auto format
        return
    end

    vim.api.nvim_create_autocmd(event, {
        buffer = bufnr,
        desc = desc,
        callback = function()
            vim.lsp.buf.format({
                name = client.name,
                bufnr = bufnr,
                async = false,
            })
        end,
    })
end

function M.setup()
    local null_ls = require('null-ls')

    null_ls.setup({
        debug = vim.env.NULLLS_DEBUG == 'true',
        on_init = function(client)
            local _supports_method = client.supports_method

            local function wrapped(obj_or_method, method)
                if type(obj_or_method) == 'string' then
                    method = obj_or_method
                end
                return _supports_method(method)
            end
            client.supports_method = wrapped
        end,
        sources = {
            null_ls.builtins.formatting.stylua,
            null_ls.builtins.formatting.prettierd.with({
                disabled_filetypes = { 'yaml' },
            }), -- graphql
            null_ls.builtins.formatting.black, -- python
            null_ls.builtins.formatting.isort, -- python
            null_ls.builtins.formatting.buf, -- proto
            null_ls.builtins.formatting.goimports_reviser.with({
                generator_opts = {
                    command = 'goimports-reviser',
                    args = {
                        '-set-alias',
                        '-use-cache',
                        '-output',
                        'file',
                        '$FILENAME',
                    },
                    to_temp_file = true,
                },
            }), -- go
            null_ls.builtins.formatting.gofumpt, -- go

            null_ls.builtins.diagnostics.golangci_lint,
            null_ls.builtins.diagnostics.codespell.with({
                args = {
                    '--config',
                    vim.env.HOME .. '/.config/codespell/config.toml',
                    '--ignore-words',
                    vim.env.HOME .. '/.config/codespell/ignore_words',
                    '-',
                },
            }),

            null_ls.builtins.code_actions.gitsigns,
            null_ls.builtins.code_actions.gomodifytags,
            null_ls.builtins.code_actions.impl,
        },
    })
    vim.api.nvim_create_autocmd('LspAttach', {
        desc = '[NullLs] set auto formatting',
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            assert(client, 'client not found')
            on_lsp_attach(client, bufnr)
        end,
    })
end

return M
