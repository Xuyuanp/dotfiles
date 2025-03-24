local M = {}

local ts = vim.treesitter

---@alias dotvim.util.ts.InjectionFormatter  fun(content: string): boolean, string

---@return dotvim.util.ts.InjectionFormatter
local function cmd_formatter(cmd)
    return function(content)
        local res = vim.system(cmd, { text = true, stdin = content }):wait()
        local ok = res.code == 0
        return ok, ok and res.stdout or res.stderr or ''
    end
end

---@type table<string, dotvim.util.ts.InjectionFormatter>
local formatters = {
    json = cmd_formatter({ 'jq' }),
    sql = cmd_formatter({ 'sqlformat', '--reindent', '--indent_columns', '--keywords=upper', '-' }),
    yaml = cmd_formatter({ 'yq', '--no-colors' }),
}

---@class dotvim.util.ts.Injection
---@field lang string
---@field type string
---@field content string
---@field range [integer, integer, integer, integer]

local function iter_injections(bufnr)
    local parser = ts.get_parser(bufnr)
    if not parser then
        return
    end

    local ft = vim.bo[bufnr].filetype
    local buf_lang = ts.language.get_lang(ft) or ft

    local query = ts.query.get(buf_lang, 'injections')
    if not query then
        return
    end

    local tree = parser:parse()[1]
    if not tree then
        return
    end

    local function is_injection(id)
        return query.captures[id] == 'injection.content'
    end

    local caps = query:iter_captures(tree:root(), bufnr)
    return vim.iter(caps):filter(is_injection)
end

local function prepend(t, x)
    table.insert(t, 1, x)
    return t
end

---@param bufnr integer
---@return dotvim.util.ts.Injection[]?
local function parse_injections(bufnr)
    local caps = iter_injections(bufnr)
    if not caps then
        return
    end

    local function should_format(_, _node, metadata)
        return metadata['format'] == 1
    end

    ---@param node TSNode
    ---@param metadata vim.treesitter.query.TSMetadata
    local function to_injection(_id, node, metadata)
        return {
            lang = metadata['injection.language'],
            type = node:type(),
            content = ts.get_node_text(node, bufnr),
            range = { node:range() },
        }
    end

    return caps:filter(should_format):map(to_injection):fold({}, prepend)
end

function M.format_injections(bufnr)
    local injections = parse_injections(bufnr) or {}

    ---@param inj dotvim.util.ts.Injection
    local function format_injection(inj)
        local format = formatters[inj.lang]
        if not format then
            return
        end
        local ok, formatted = format(inj.content)
        if not ok then
            return
        end
        if formatted == inj.content then
            return
        end

        local lines = vim.split(formatted, '\n')
        local start_row, start_col = inj.range[1], inj.range[2]
        local end_row, end_col = inj.range[3], inj.range[4]
        vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
    end

    vim.iter(injections):each(format_injection)
end

return M
