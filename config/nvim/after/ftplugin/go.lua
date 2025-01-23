vim.b.lsp_disable_auto_format = true

vim.b.blink_auto_show_menu = function(ctx)
    --[[
    --suppress completion menu when the line ends with a colon(case xx:)
    --]]
    if ctx.line:len() > 0 and vim.endswith(ctx.line, ':') then
        -- the delay is required
        vim.schedule(function()
            require('blink.cmp.completion.list').hide()
        end)
        return false
    end
    return true
end
