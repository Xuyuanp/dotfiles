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
    return query:iter_captures(tree:root(), bufnr)
end

local function prepend(t, x)
    table.insert(t, 1, x)
    return t
end

---@param bufnr integer
---@return dotvim.util.ts.Injection[]|nil
local function parse_injections(bufnr)
    local caps = iter_injections(bufnr)
    if not caps then
        return
    end

    ---@param node TSNode?
    local function no_skip(_, node)
        while node do
            local prev_sib = node:prev_sibling()
            if prev_sib and prev_sib:type() == 'comment' then
                local comment = ts.get_node_text(prev_sib, bufnr)
                -- if the comment contains 'skip-format-injection', skip
                return not comment:find('skip%-format%-injection')
            end
            node = node:parent()
        end

        return true
    end

    local function to_injection(_, node, metadata)
        return {
            lang = metadata['injection.language'],
            type = node:type(),
            content = ts.get_node_text(node, bufnr),
            range = { node:range() },
        }
    end

    return vim.iter(caps):filter(no_skip):map(to_injection):fold({}, prepend)
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
        formatted = vim.trim(formatted)
        if formatted == inj.content then
            return
        end

        local lines = vim.split(formatted, '\n')
        local start_line, start_col = inj.range[1], inj.range[2]
        local end_line, end_col = inj.range[3], inj.range[4]
        vim.api.nvim_buf_set_text(bufnr, start_line, start_col, end_line, end_col, lines)
    end

    vim.iter(injections):each(format_injection)
end

return M
