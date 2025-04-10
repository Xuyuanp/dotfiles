local M = {}

local SystemPrompt = [[
Keep your answers short and impersonal.
The programmer will provide you with a set of recently viewed files, their recent edits, and a snippet of code that is being actively edited.

When helping the programmer, your goals are:
- Make only the necessary changes as indicated by the context.
- Avoid unnecessary rewrites and make only the necessary changes, using ellipses to indicate partial code where appropriate.
- Ensure all specified additions, modifications, and new elements (e.g., methods, parameters, function calls) are included in the response.
- Adhere strictly to the provided pattern, structure, and content, including matching the exact structure and formatting of the expected response.
- Maintain the integrity of the existing code while making necessary updates.
- Provide complete and detailed code snippets without omissions, ensuring all necessary parts such as additional classes, methods, or specific steps are included.
- Keep the programmer on the pattern that you think they are on.
- Consider what edits need to be made next, if any.

When responding to the programmer, you must follow these rules:
- Only answer with the updated code. The programmer will copy and paste your code as is in place of the programmer's provided snippet.
- Match the expected response exactly, even if it includes errors or corruptions, to ensure consistency.
- Do not alter method signatures, add or remove return values, or modify existing logic unless explicitly instructed.
- The current cursor position is indicated by <|cursor|>. You MUST keep the cursor position the same in your response.
- DO NOT REMOVE <|cursor|>.
- You must ONLY reply using the tag: <next-version>.
]]

local UserPromptTemplate = [[
These are the files I'm working on, before I started making changes to them:
<original_code>
%s:
%s
</original_code>

This is a sequence of edits that I made on these files, starting from the oldest to the newest:
<edits_to_original_code>
```
---%s:
+++%s:
%s
```
</edits_to_original_code>

Here is the piece of code I am currently editing in %s:

<current-version>
```%s
%s
```
</current-version>

Based on my most recent edits, what will I do next? Rewrite the code between <current-version> and </current-version> based on what I will do next. Do not skip any lines. Do not be lazy.
]]

---@class NesContext
---@field bufnr number
---@field cursor [integer, integer]
---@field original_code string
---@field edits string
---@field current_version string
---@field filename string
---@field filetype string
local Context = {}
Context.__index = Context

function Context.new(bufnr)
    local self = {
        bufnr = bufnr,
        cursor = vim.api.nvim_win_get_cursor(0),
        original_code = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr)),
        edits = vim.diff(
            vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr)),
            table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n'),
            { algorithm = 'minimal' }
        ),
        current_version = M.get_current_version(bufnr),
        filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':'),
        filetype = vim.bo[bufnr].filetype,
    }
    setmetatable(self, Context)
    return self
end

function Context:payload()
    return {
        messages = {
            {
                role = 'system',
                content = SystemPrompt,
            },
            {
                role = 'user',
                content = UserPromptTemplate:format(
                    self.original_code,
                    self.filename,
                    self.edits,
                    self.filename,
                    self.filename,
                    self.current_version
                ),
            },
        },
        model = 'copilot-nes-v',
        temperature = 0,
        top_p = 1,
        prediction = {
            type = 'content',
            content = string.format('<next-version>\n```%s\n%s\n```\n</next-version>', self.filetype, self.current_version),
        },
        n = 1,
        stream = true,
        snippy = {
            enabled = false,
        },
    }
end

function M.get_diff(bufnr)
    local original = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr))
    local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
    return vim.diff(original, current, { algorithm = 'minimal' })
end

function M.get_current_version(bufnr)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local start_row = row - 20
    if start_row < 0 then
        start_row = 0
    end
    local end_row = row + 20
    if end_row >= vim.api.nvim_buf_line_count(bufnr) then
        end_row = vim.api.nvim_buf_line_count(bufnr) - 1
    end
    local end_col = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1]:len()

    local before_cursor = vim.api.nvim_buf_get_text(bufnr, start_row, 0, row, col, {})
    local after_cursor = vim.api.nvim_buf_get_text(bufnr, row, col, end_row, end_col, {})
    return string.format('%s<|cursor|>%s', table.concat(before_cursor, '\n'), table.concat(after_cursor, '\n'))
end

function M.get_context(bufnr)
    local fullpath = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(fullpath, ':.')

    local original = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr), '')
    local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
    local diff = vim.diff(table.concat(original, '\n'), current, { algorithm = 'minimal' })

    local original_code = table.concat(
        vim.iter(original)
            :enumerate()
            :map(function(i, line)
                return string.format('%d│%s', i, line)
            end)
            :totable(),
        '\n'
    )
    local current_version = M.get_current_version(bufnr)
    return UserPromptTemplate:format(filename, original_code, filename, filename, diff, filename, vim.bo[bufnr].filetype, current_version),
        current_version
end

function M.payload(bufnr)
    local context, current_version = M.get_context(bufnr)
    local payload = {
        messages = {
            {
                role = 'system',
                content = SystemPrompt,
            },
            {
                role = 'user',
                content = context,
            },
        },
        model = 'copilot-nes-v',
        temperature = 0,
        top_p = 1,
        prediction = {
            type = 'content',
            content = string.format('<next-version>\n```go\n%s\n```\n</next-version>', current_version),
        },
        n = 1,
        stream = true,
        snippy = {
            enabled = false,
        },
    }
    vim.system({ 'python', '/Users/pangxuyuan/.config/nvim/nes.py' }, {
        stdin = vim.json.encode(payload),
        text = true,
    }, function(obj)
        assert(obj.code == 0, obj.stderr)
        local next_version = vim.trim(obj.stdout)
        assert(next_version)
        if not vim.startswith(next_version, '<next-version>') then
            vim.print('not found')
            return
        end
        local old_version = string.format('<next-version>\n```go\n%s\n```\n</next-version>', current_version)
        vim.print(old_version)
        vim.print('---')
        vim.print(next_version)
        vim.print('---')
        print(vim.diff(old_version, next_version, {
            algorithm = 'minimal',
            ignore_cr_at_eol = true,
            ignore_whitespace_change_at_eol = true,
        }))
    end)
end

function M.setup(opts)
    opts = opts or {}
    vim.keymap.set('i', '<A-i>', function()
        require('dotvim.config.nes.gemini').get_suggestion()
        -- local bufnr = vim.api.nvim_get_current_buf()
        -- M.payload(bufnr)
    end)
end

return M
