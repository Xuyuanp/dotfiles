---@type vim.lsp.Config
return {
    ---@type lspconfig.settings.rust_analyzer
    settings = {
        ['rust-analyzer'] = {
            diagnostics = {
                enable = true,
                disabled = { 'unresolved-proc-macro' },
            },
            -- rust-analyzer.semanticHighlighting.strings.enable
            semanticHighlighting = {
                strings = {
                    enable = false,
                },
            },
        },
    },
}
