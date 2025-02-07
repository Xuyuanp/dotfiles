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

---@package
---@alias InjectionFormatter  fun(content: string): boolean, string

---@type InjectionFormatter
local function format_json(content)
    local res = vim.system({ 'jq' }, { text = true, stdin = content }):wait()
    local ok = res.code == 0
    return ok, ok and res.stdout or res.stderr or ''
end

---@type table<string, InjectionFormatter>
local formatters = {
    json = format_json,
}

local function format_json_strings(bufnr)
    local ts = vim.treesitter

    local parser = ts.get_parser(bufnr)
    if not parser then
        return
    end

    local query = ts.query.get('go', 'injections')
    if not query then
        return
    end

    local tree = parser:parse()[1]
    if not tree then
        return
    end

    local injections = {}

    for _, node, metadata in query:iter_captures(tree:root(), bufnr) do
        local lang = metadata['injection.language'] --[[@as string]]
        local content = ts.get_node_text(node, bufnr)
        local range = { node:range() }
        -- reverse the order to avoid the conflict of ranges
        table.insert(injections, 1, {
            lang = lang,
            content = content,
            range = range,
        })
    end

    vim.iter(injections):each(function(inj)
        local format = formatters[inj.lang]
        if not format then
            return
        end
        local ok, formatted = format(inj.content)
        if not ok then
            return
        end
        formatted = vim.trim(formatted)
        if formatted == inj.content then
            return
        end

        local lines = vim.split(formatted, '\n')
        local start_line, start_col = inj.range[1], inj.range[2]
        local end_line, end_col = inj.range[3], inj.range[4]
        vim.api.nvim_buf_set_text(bufnr, start_line, start_col, end_line, end_col, lines)
    end)
end

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
    buffer = vim.api.nvim_get_current_buf(),
    desc = 'format json strings',
    callback = function(args)
        if vim.b.injection_format_disabled or vim.g.go_injection_format_disabled then
            return
        end
        format_json_strings(args.buf)
    end,
})
