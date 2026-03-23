---@type vim.lsp.Config
return {
    cmd = { 'elixir-ls' },
    ---@type lspconfig.settings.elixirls
    settings = {
        elixirLS = {
            dialyzerEnabled = true,
            fetchDeps = false,
            mixEnv = 'dev',
        },
    },
    cmd_env = { PATH = vim.fs.joinpath(vim.env.HOME, '.local/share/mise/shims:') .. vim.env.PATH },
}
