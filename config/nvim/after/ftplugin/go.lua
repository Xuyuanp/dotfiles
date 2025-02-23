vim.b.lsp_disable_auto_format = true

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
    buffer = vim.api.nvim_get_current_buf(),
    desc = 'format injections',
    callback = function(args)
        if vim.b.injection_format_disabled or vim.g.go_injection_format_disabled then
            return
        end
        require('dotvim.util.ts').format_injections(args.buf)
    end,
})
