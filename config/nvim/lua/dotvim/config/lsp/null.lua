local M = {}

local function on_lsp_attach(client, bufnr)
    local support_formatting = client.supports_method('textDocument/formatting')
    if not support_formatting then
        return
    end

    local event = 'BufWritePre'
    local desc = 'Formatting on save by lsp ' .. client.name

    if client.name == 'null-ls' then
        event = 'BufWritePost'
    elseif vim.b[bufnr].lsp_disable_auto_format then
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
        sources = {
            -- formatting
            null_ls.builtins.formatting.stylua,
            null_ls.builtins.formatting.prettierd, -- graphql
            null_ls.builtins.formatting.black, -- python
            null_ls.builtins.formatting.buf, -- proto
            null_ls.builtins.formatting.taplo, -- toml
            null_ls.builtins.formatting.jq, -- json
            null_ls.builtins.formatting.trim_whitespace,
            null_ls.builtins.formatting.goimports_reviser.with({
                generator_opts = {
                    command = 'goimports-reviser',
                    args = { '-set-alias', '-use-cache', '-rm-unused', '-output', 'stdout', '$FILENAME' },
                    to_stdin = true,
                },
            }),

            -- diagnostics
            null_ls.builtins.diagnostics.codespell,

            -- code_actions
            null_ls.builtins.code_actions.gitsigns,
            null_ls.builtins.code_actions.gomodifytags,
        },
    })
    require('dotvim.util').on_lsp_attach(on_lsp_attach, { desc = 'set auto formatting trigger' })
end

return M