vim.b.lsp_disable_auto_format = true

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
    buffer = vim.api.nvim_get_current_buf(),
    desc = 'format injections',
    callback = function(args)
        if vim.b.injection_format_disabled or vim.g.go_injection_format_disabled then
            return
        end
        local function transform(inj, lines)
            if inj.type == 'interpreted_string_literal_content' then
                lines[1] = '`' .. lines[1]
                lines[#lines] = lines[#lines] .. '`'
                inj.range[2] = inj.range[2] - 1
                inj.range[4] = inj.range[4] + 1
            end
            return inj, lines
        end
        require('dotvim.util.ts').format_injections(args.buf, transform)
    end,
})
