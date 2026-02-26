--- Redact sensitive variable values in shell/env buffers.
---
--- Uses virt_text overlay instead of conceal, so each character renders as '*'
--- with matching width. Native conceal collapses the entire region into a
--- single character, which is unreadable.
---
--- Activated via ftplugin for sh/bash/zsh. Toggle: yoS

local M = {}

local ns = vim.api.nvim_create_namespace('dotvim.secret_redact')

local sensitive_keywords = {
    'SECRET',
    'TOKEN',
    'PASSWORD',
    'PASSWD',
    'API_KEY',
    'APIKEY',
    'PRIVATE_KEY',
    'ACCESS_KEY',
    'CREDENTIAL',
    'AUTH',
}

--- Matches `[export] NAME=VALUE` in bash/sh/zsh ASTs.
--- `(_) @value` captures all value node types: raw_string, string, word.
local query_string = [[
(variable_assignment
  name: (variable_name) @name
  value: (_) @value)
]]

local function is_sensitive(name)
    local upper = name:upper()
    for _, kw in ipairs(sensitive_keywords) do
        if upper:find(kw, 1, true) then
            return true
        end
    end
    return false
end

--- @param buf integer
--- @return {[1]: integer, [2]: integer, [3]: integer}[]
local function collect_sensitive_ranges(buf)
    local parser = vim.treesitter.get_parser(buf)
    if not parser then
        return {}
    end

    local ok, query = pcall(vim.treesitter.query.parse, parser:lang(), query_string)
    if not ok then
        return {}
    end

    local ranges = {}
    for _, tree in ipairs(parser:parse() or {}) do
        for _, match in query:iter_matches(tree:root(), buf, 0, -1, { all = true }) do
            local name_nodes, value_nodes = match[1], match[2]
            if not name_nodes or not value_nodes then
                goto continue
            end
            if not is_sensitive(vim.treesitter.get_node_text(name_nodes[1], buf)) then
                goto continue
            end
            for _, value_node in ipairs(value_nodes) do
                local sr, sc, er, ec = value_node:range()
                -- multi-line values (heredoc etc.) are rare in env files; skip them
                -- to avoid partial overlays that misalign
                if sr == er and ec > sc then
                    ranges[#ranges + 1] = { sr, sc, ec }
                end
            end
            ::continue::
        end
    end
    return ranges
end

--- @param buf integer
--- @param reveal_rows? table<integer, boolean> 0-indexed rows to leave unredacted
function M.apply(buf, reveal_rows)
    buf = buf or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if vim.b[buf].secret_redact_revealed then
        return
    end

    for _, range in ipairs(collect_sensitive_ranges(buf)) do
        local row, sc, ec = range[1], range[2], range[3]
        if not (reveal_rows and reveal_rows[row]) then
            vim.api.nvim_buf_set_extmark(buf, ns, row, sc, {
                end_col = ec,
                virt_text = { { string.rep('*', ec - sc), 'SecretRedacted' } },
                virt_text_pos = 'overlay',
            })
        end
    end
end

function M.toggle(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    vim.b[buf].secret_redact_revealed = not vim.b[buf].secret_redact_revealed
    M.apply(buf)
end

function M.setup(buf)
    buf = buf or vim.api.nvim_get_current_buf()

    if vim.b[buf].secret_redact_attached then
        return
    end
    vim.b[buf].secret_redact_attached = true

    vim.api.nvim_set_hl(0, 'SecretRedacted', { link = 'SpecialComment', default = true })

    M.apply(buf)

    local augroup = vim.api.nvim_create_augroup('dotvim.secret_redact.' .. buf, { clear = true })

    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
        buffer = buf,
        group = augroup,
        callback = function()
            M.apply(buf)
        end,
    })

    -- Visual mode: reveal only the selected lines so the user can see/yank
    -- specific values without exposing the entire file. A separate augroup
    -- keeps the CursorMoved listener easy to tear down on mode exit.

    local visual_augroup = vim.api.nvim_create_augroup('dotvim.secret_redact.visual.' .. buf, { clear = true })

    local function get_visual_rows()
        local s = vim.fn.getpos('v')[2] - 1 -- 0-indexed
        local e = vim.fn.getpos('.')[2] - 1
        if s > e then
            s, e = e, s
        end
        local rows = {}
        for r = s, e do
            rows[r] = true
        end
        return rows
    end

    local function reveal_selection()
        M.apply(buf, get_visual_rows())
    end

    -- Track visual state ourselves because ModeChanged fires for every
    -- transition (v->V, V->n, etc.) and we only care about enter/leave.
    local in_visual = false
    vim.api.nvim_create_autocmd('ModeChanged', {
        buffer = buf,
        group = augroup,
        callback = function()
            local mode = vim.fn.mode()
            local is_visual = mode == 'v' or mode == 'V' or mode == '\22'
            if is_visual and not in_visual then
                in_visual = true
                reveal_selection()
                -- CursorMoved updates the reveal as the selection grows/shrinks
                vim.api.nvim_create_autocmd('CursorMoved', {
                    buffer = buf,
                    group = visual_augroup,
                    callback = function()
                        if not in_visual then
                            return true
                        end
                        reveal_selection()
                    end,
                })
            elseif not is_visual and in_visual then
                in_visual = false
                vim.api.nvim_clear_autocmds({ group = visual_augroup })
                M.apply(buf)
            end
        end,
    })

    vim.keymap.set('n', 'yoS', function()
        M.toggle(buf)
    end, { buffer = buf, desc = 'Toggle secret redaction' })
end

return M
