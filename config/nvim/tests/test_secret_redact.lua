local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

local ns = vim.api.nvim_create_namespace('dotvim.secret_redact')

local function create_buf(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = 'bash'
    vim.treesitter.start(buf, 'bash')
    return buf
end

local function delete_buf(buf)
    -- reset buffer state so setup() can re-attach on reuse
    vim.b[buf].secret_redact_attached = nil
    vim.b[buf].secret_redact_revealed = nil
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
end

local function get_marks(buf)
    return vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
end

local function mark_rows(buf)
    local rows = {}
    for _, m in ipairs(get_marks(buf)) do
        table.insert(rows, m[2])
    end
    table.sort(rows)
    return rows
end

local function mark_virt_text(buf, row)
    for _, m in ipairs(get_marks(buf)) do
        if m[2] == row then
            return m[4].virt_text[1][1]
        end
    end
    return nil
end

-- =============================================================================
-- apply()
-- =============================================================================

T['apply()'] = new_set()

T['apply()']['redacts sensitive variables'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "export API_KEY='sk-1234567890'",
        'export AWS_SECRET_ACCESS_KEY="AKIAIOSFODNN7"',
        'DB_PASSWORD=mysecretpassword',
        "AUTH_TOKEN='bearer xyz'",
    })

    sr.apply(buf)

    eq(mark_rows(buf), { 0, 1, 2, 3 })

    delete_buf(buf)
end

T['apply()']['skips non-sensitive variables'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'export HOME=/home/user',
        "NORMAL_VAR='hello'",
        'PATH=/usr/bin',
        'export EDITOR=nvim',
    })

    sr.apply(buf)

    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

T['apply()']['handles mixed sensitive and non-sensitive'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'export HOME=/home/user',
        "export API_KEY='sk-1234'",
        'NORMAL_VAR=hello',
        'DB_PASSWORD=secret',
        'export EDITOR=nvim',
    })

    sr.apply(buf)

    eq(mark_rows(buf), { 1, 3 })

    delete_buf(buf)
end

T['apply()']['overlay width matches value width'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "export API_KEY='short'",
        'TOKEN=abc',
    })

    sr.apply(buf)

    -- 'short' is 7 chars (including quotes)
    eq(mark_virt_text(buf, 0), '*******')
    -- abc is 3 chars
    eq(mark_virt_text(buf, 1), '***')

    delete_buf(buf)
end

T['apply()']['handles single-quoted values'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='value'",
    })

    sr.apply(buf)

    local marks = get_marks(buf)
    eq(#marks, 1)
    eq(marks[1][3], 8) -- col start at quote
    eq(marks[1][4].end_col, 15) -- col end after closing quote

    delete_buf(buf)
end

T['apply()']['handles double-quoted values'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'SECRET="myvalue"',
    })

    sr.apply(buf)

    local marks = get_marks(buf)
    eq(#marks, 1)
    eq(marks[1][3], 7) -- col start at quote
    eq(marks[1][4].end_col, 16) -- col end after closing quote

    delete_buf(buf)
end

T['apply()']['handles unquoted values'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'API_KEY=unquoted_value',
    })

    sr.apply(buf)

    local marks = get_marks(buf)
    eq(#marks, 1)
    eq(marks[1][3], 8) -- col start after =
    eq(marks[1][4].end_col, 22)

    delete_buf(buf)
end

T['apply()']['skips empty values'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'PASSWORD=',
    })

    sr.apply(buf)

    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

T['apply()']['clears previous marks before reapplying'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='value1'",
    })

    sr.apply(buf)
    eq(#get_marks(buf), 1)

    sr.apply(buf)
    eq(#get_marks(buf), 1) -- still 1, not 2

    delete_buf(buf)
end

T['apply()']['skips when revealed'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='value'",
    })

    vim.b[buf].secret_redact_revealed = true
    sr.apply(buf)

    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

-- =============================================================================
-- apply() with reveal_rows
-- =============================================================================

T['apply() reveal_rows'] = new_set()

T['apply() reveal_rows']['reveals only specified rows'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
        "SECRET='ccc'",
    })

    sr.apply(buf, { [1] = true })

    -- row 0 and 2 should be redacted, row 1 revealed
    eq(mark_rows(buf), { 0, 2 })

    delete_buf(buf)
end

T['apply() reveal_rows']['reveals multiple rows'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
        "SECRET='ccc'",
        "PASSWORD='ddd'",
    })

    sr.apply(buf, { [0] = true, [2] = true })

    eq(mark_rows(buf), { 1, 3 })

    delete_buf(buf)
end

T['apply() reveal_rows']['reveals all when all rows specified'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
    })

    sr.apply(buf, { [0] = true, [1] = true })

    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

T['apply() reveal_rows']['no effect on non-sensitive rows'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'HOME=/home/user',
        "API_KEY='aaa'",
    })

    -- revealing row 0 (non-sensitive) should have no effect
    sr.apply(buf, { [0] = true })

    eq(mark_rows(buf), { 1 })

    delete_buf(buf)
end

-- =============================================================================
-- apply() keyword coverage
-- =============================================================================

T['apply() keywords'] = new_set()

T['apply() keywords']['detects all sensitive keywords'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'MY_SECRET=a',
        'MY_TOKEN=b',
        'MY_PASSWORD=c',
        'MY_PASSWD=d',
        'MY_API_KEY=e',
        'MY_APIKEY=f',
        'MY_PRIVATE_KEY=g',
        'MY_ACCESS_KEY=h',
        'MY_CREDENTIAL=i',
        'MY_AUTH=j',
    })

    sr.apply(buf)

    eq(#get_marks(buf), 10)

    delete_buf(buf)
end

T['apply() keywords']['is case-insensitive on variable name'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        'api_key=value1',
        'Api_Token=value2',
        'db_password=value3',
    })

    sr.apply(buf)

    eq(#get_marks(buf), 3)

    delete_buf(buf)
end

-- =============================================================================
-- toggle()
-- =============================================================================

T['toggle()'] = new_set()

T['toggle()']['reveals all marks'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
    })

    sr.apply(buf)
    eq(#get_marks(buf), 2)

    sr.toggle(buf)

    eq(vim.b[buf].secret_redact_revealed, true)
    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

T['toggle()']['re-hides marks'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
    })

    sr.apply(buf)
    sr.toggle(buf) -- reveal
    sr.toggle(buf) -- re-hide

    eq(vim.b[buf].secret_redact_revealed, false)
    eq(#get_marks(buf), 2)

    delete_buf(buf)
end

-- =============================================================================
-- setup()
-- =============================================================================

T['setup()'] = new_set()

T['setup()']['applies redaction on attach'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        'NORMAL=hello',
    })

    sr.setup(buf)

    eq(#get_marks(buf), 1)
    eq(vim.b[buf].secret_redact_attached, true)

    delete_buf(buf)
end

T['setup()']['guards against double attach'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
    })

    sr.setup(buf)
    sr.setup(buf) -- second call should be no-op

    eq(#get_marks(buf), 1)

    delete_buf(buf)
end

T['setup()']['creates toggle keymap'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
    })

    -- switch to the buffer so buffer-local keymaps work
    vim.api.nvim_set_current_buf(buf)
    sr.setup(buf)

    local maps = vim.api.nvim_buf_get_keymap(buf, 'n')
    local found = false
    for _, map in ipairs(maps) do
        if map.lhs == 'yoS' then
            found = true
            break
        end
    end
    eq(found, true)

    delete_buf(buf)
end

T['setup()']['sets SecretRedacted highlight'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({ "API_KEY='aaa'" })

    sr.setup(buf)

    local hl = vim.api.nvim_get_hl(0, { name = 'SecretRedacted' })
    eq(hl.link, 'Comment')

    delete_buf(buf)
end

T['setup()']['refreshes on text change'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
    })
    sr.setup(buf)
    eq(#get_marks(buf), 1)

    -- append a new sensitive line
    vim.api.nvim_buf_set_lines(buf, 1, 1, false, { "TOKEN='bbb'" })
    -- force treesitter reparse
    vim.treesitter.get_parser(buf):parse()
    -- fire TextChanged
    vim.api.nvim_exec_autocmds('TextChanged', { buffer = buf })

    eq(#get_marks(buf), 2)

    delete_buf(buf)
end

-- =============================================================================
-- visual mode reveal
-- =============================================================================

T['visual reveal'] = new_set()

T['visual reveal']['ModeChanged clears selected rows only'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
        "TOKEN='bbb'",
        "SECRET='ccc'",
    })

    sr.setup(buf)
    eq(#get_marks(buf), 3)

    -- simulate: apply with row 1 revealed (as ModeChanged would)
    sr.apply(buf, { [1] = true })
    eq(mark_rows(buf), { 0, 2 })

    -- restore full redaction (as leaving visual would)
    sr.apply(buf)
    eq(#get_marks(buf), 3)

    delete_buf(buf)
end

T['visual reveal']['preserves revealed state'] = function()
    local sr = require('dotvim.util.secret_redact')
    local buf = create_buf({
        "API_KEY='aaa'",
    })

    sr.setup(buf)
    sr.toggle(buf) -- reveal all
    eq(#get_marks(buf), 0)

    -- apply with reveal_rows should still show nothing (globally revealed)
    sr.apply(buf, { [0] = true })
    eq(#get_marks(buf), 0)

    delete_buf(buf)
end

return T
