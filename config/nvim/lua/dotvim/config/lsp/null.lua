local M = {}

function M.setup()
    local null_ls = require('null-ls')

    null_ls.setup({
        debug = vim.env.NULLLS_DEBUG == 'true',
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
end

return M
