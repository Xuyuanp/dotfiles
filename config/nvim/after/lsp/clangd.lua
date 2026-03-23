---@type vim.lsp.Config
return {
    -- disable clangd for proto files
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
}
