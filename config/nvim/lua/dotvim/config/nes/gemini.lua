local M = {}

local api = vim.api
local fn = vim.fn
local json = vim.json -- Use built-in JSON if available, or plenary's

-- --- Configuration ---
-- IMPORTANT: Replace with your actual API endpoint and Key/Token
M.config = {
    api_endpoint = 'YOUR_API_ENDPOINT_HERE', -- e.g., "https://api.example.com/v1/chat/completions"
    api_key = os.getenv('NEXT_EDIT_API_KEY'), -- Read from environment variable for security
    -- model = 'copilot-nes-v',
    model = 'ppe-nes-control',
    request_timeout = 30000, -- 30 seconds
    context_lines_before = 20, -- Lines of context before cursor for the <current-version> snippet
    context_lines_after = 20, -- Lines of context after cursor for the <current-version> snippet
    suggestion_float_opts = {
        border = 'rounded',
        style = 'minimal',
        zindex = 50,
    },
}

-- Store the last suggestion to apply it later
local last_suggestion = {
    code = nil,
    start_line = nil, -- 0-indexed
    end_line = nil, -- 0-indexed
    cursor_marker = '<|cursor|>',
    cursor_pos = nil, -- {line, col} relative to the suggestion start, 0-indexed
}

-- --- Helper Functions ---

local function notify(msg, level)
    level = level or vim.log.levels.INFO
    vim.notify(msg, level, { title = 'NES' })
end

-- Simple function to get buffer content as a list of strings
local function get_buffer_content(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    return api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

-- Simplified context gathering. A real implementation needs Git integration.
local function gather_context()
    local bufnr = api.nvim_get_current_buf()
    local filepath = api.nvim_buf_get_name(bufnr)
    if filepath == '' then
        notify('Cannot get suggestion for unnamed buffer.', vim.log.levels.WARN)
        return nil
    end
    local filename = vim.fn.fnamemodify(filepath, ':.')
    local filetype = vim.bo[bufnr].filetype
    local current_lines = get_buffer_content(bufnr)
    local cursor_pos = api.nvim_win_get_cursor(0) -- [row, col], 1-based
    local current_line_count = #current_lines

    -- 1. Original Code (Simplification: Using current content)
    -- TODO: Replace this with `git show HEAD:<filepath>` for accuracy
    local original_code_formatted = {}
    table.insert(original_code_formatted, filename .. ':')
    local original_code_lines = vim.fn.readfile(filepath, '')
    for i, line in ipairs(original_code_lines) do
        table.insert(original_code_formatted, string.format('%d│%s', i, line))
    end
    local original_code_formatted = table.concat(original_code_formatted, '\n')

    -- 2. Edits (Simplification: Empty diff)
    -- TODO: Replace this with `git diff HEAD -- <filepath>` and format as diff
    local original = vim.fn.readfile(vim.api.nvim_buf_get_name(bufnr), '')
    local current = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
    local diff = vim.diff(table.concat(original, '\n'), current, { algorithm = 'minimal' })
    local edits_content = '```\n---' .. filename .. ':\n+++' .. filename .. ':\n' .. diff .. '```'

    -- 3. Current Snippet
    local snippet_start_line = math.max(1, cursor_pos[1] - M.config.context_lines_before)
    local snippet_end_line = math.min(current_line_count, cursor_pos[1] + M.config.context_lines_after)
    local snippet_lines = {}
    local cursor_relative_line = 0 -- 0-indexed line within the snippet where cursor is
    local cursor_col = cursor_pos[2] -- 0-indexed col

    -- if snippet_start_line > 1 then
    --     table.insert(snippet_lines, '…')
    -- end

    for i = snippet_start_line, snippet_end_line do
        local line_content = current_lines[i]
        if i == cursor_pos[1] then
            cursor_relative_line = #snippet_lines -- Add cursor marker *before* inserting the line
            -- Insert cursor marker carefully
            line_content = vim.fn.strpart(line_content, 0, cursor_col) .. last_suggestion.cursor_marker .. vim.fn.strpart(line_content, cursor_col)
        end
        table.insert(snippet_lines, line_content)
    end

    -- if snippet_end_line < current_line_count then
    --     table.insert(snippet_lines, '…')
    -- end

    local current_version_content = string.format('```%s\n%s\n```', filetype, table.concat(snippet_lines, '\n'))

    return {
        original_code = original_code_formatted,
        edits = edits_content,
        current_version = current_version_content,
        filepath = filepath,
        -- Store context needed for applying the suggestion later
        snippet_start_line_1based = snippet_start_line,
        snippet_end_line_1based = snippet_end_line,
        cursor_relative_line_0based = cursor_relative_line,
        cursor_col_0based = cursor_col,
    }
end

-- --- API Interaction ---

-- Construct the JSON payload based on the VS Code example
local function construct_request_payload(context)
    if not context then
        return nil
    end

    vim.print(context.edits)
    vim.print(context.current_version)

    local messages = {
        {
            role = 'system',
            content = [[Keep your answers short and impersonal.
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
- You MUST keep <|cursor|> in your response.
- Only answer with the updated code. The programmer will copy and paste your code as is in place of the programmer's provided snippet.
- Match the expected response exactly, even if it includes errors or corruptions, to ensure consistency.
- Do not alter method signatures, add or remove return values, or modify existing logic unless explicitly instructed.
- The current cursor position is indicated by <|cursor|>. You must keep the cursor position the same in your response.
- You must ONLY reply using the tag: <next-version>.
]],
        },
        {
            role = 'user',
            content = string.format(
                [[These are the files I'm working on, before I started making changes to them:
<original_code>
%s
</original_code>

This is a sequence of edits that I made on these files, starting from the oldest to the newest:
<edits_to_original_code>
%s
</edits_to_original_code>

Here is the piece of code I am currently editing in %s:

<current-version>
%s
</current-version>

Based on my most recent edits, what will I do next? Rewrite the code between <current-version> and </current-version> based on what I will do next. Do not skip any lines. Do not be lazy.]],
                context.original_code,
                context.edits,
                context.filepath,
                context.current_version
            ),
        },
    }

    local payload = {
        messages = messages,
        model = M.config.model,
        temperature = 0,
        top_p = 1,
        n = 1,
        prediction = {
            type = 'content',
            content = string.format('<next-version>\n%s\n</next-version>\n', context.current_version),
        },
        stream = true, -- Request streaming response
        snippy = { enabled = false }, -- This might be specific to the VSCode API, include if necessary
    }

    return json.encode(payload)
end

-- Call the API endpoint (handles stream)
local function call_suggestion_api(payload, callback)
    vim.system({ 'python', '/Users/pangxuyuan/.config/nvim/nes.py' }, {
        stdin = payload,
        text = true,
    }, function(obj)
        assert(obj.code == 0, obj.stderr)
        callback(nil, obj.stdout)
    end)
end

-- --- Response Parsing & Display ---

local function parse_response(response_text)
    if not response_text then
        return nil
    end

    -- Find the content within the <next-version> tags
    local start_tag = '<next-version>'
    local end_tag = '</next-version>'
    local start_idx = response_text:find(start_tag, 1, true) -- Plain search
    local end_idx = response_text:find(end_tag, 1, true)

    if not start_idx or not end_idx then
        notify('Could not find <next-version> tags in response.', vim.log.levels.WARN)
        print('Raw Response:\n', response_text)
        return nil
    end

    local content_with_wrapper = response_text:sub(start_idx + #start_tag, end_idx - 1)
    vim.print(content_with_wrapper)

    -- Extract code block content (assuming ```language ... ```)
    local code_block_pattern = '```.-%s*(.-)%s*```' -- Non-greedy match for content
    local code_content = content_with_wrapper:match(code_block_pattern)

    if not code_content then
        -- Fallback: maybe no ``` wrapper? Use content directly.
        code_content = content_with_wrapper:match('^%s*(.*)%s*$') -- Trim whitespace
        if code_content:startsWith('\n') then
            code_content = code_content:sub(2)
        end -- Remove leading newline if present
        notify('Could not find code block ``` markers, using raw content inside tags.', vim.log.levels.WARN)
    end

    if not code_content or code_content == '' then
        notify('Extracted code content is empty.', vim.log.levels.WARN)
        print('Content within tags:\n', content_with_wrapper)
        return nil
    end

    -- Find cursor position and remove marker
    local cursor_line = -1
    local cursor_col = -1
    local cleaned_lines = {}
    local lines = vim.split(code_content, '\n', { trimempty = false }) -- Keep empty lines

    for i, line in ipairs(lines) do
        local col = line:find(last_suggestion.cursor_marker, 1, true)
        if col then
            if cursor_line ~= -1 then
                notify('Warning: Found multiple cursor markers in suggestion.', vim.log.levels.WARN)
            end
            cursor_line = i - 1 -- 0-indexed line
            cursor_col = col - 1 -- 0-indexed column
            -- Remove the marker
            line = line:sub(1, col - 1) .. line:sub(col + #last_suggestion.cursor_marker)
        end
        table.insert(cleaned_lines, line)
    end

    if cursor_line == -1 then
        notify('Warning: Cursor marker <|cursor|> not found in the suggestion.', vim.log.levels.WARN)
        -- Default cursor to end of suggestion if not found? Or beginning? Let's try end of first line.
        cursor_line = 0
        cursor_col = #(cleaned_lines[1] or '')
    end

    last_suggestion.cursor_pos = { line = cursor_line, col = cursor_col }

    return cleaned_lines -- Return as a list of strings
end

-- Display suggestion in a floating window
local float_win = { buf = nil, win = nil }

local function close_float_win()
    if float_win.win and api.nvim_win_is_valid(float_win.win) then
        api.nvim_win_close(float_win.win, true)
    end
    if float_win.buf and api.nvim_buf_is_valid(float_win.buf) then
        api.nvim_buf_delete(float_win.buf, { force = true })
    end
    float_win.buf = nil
    float_win.win = nil
end

local function display_suggestion(lines)
    vim.print(lines)
    if true then
        return
    end

    close_float_win() -- Close previous suggestion window if any

    if not lines or #lines == 0 then
        notify('No suggestion to display.', vim.log.levels.WARN)
        return
    end

    local filetype = api.nvim_buf_get_option(api.nvim_get_current_buf(), 'filetype')

    -- Create a temporary buffer for the suggestion
    float_win.buf = api.nvim_create_buf(false, true) -- `listed=false`, `scratch=true`
    api.nvim_buf_set_option(float_win.buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(float_win.buf, 'swapfile', false)
    api.nvim_buf_set_option(float_win.buf, 'modifiable', false)
    api.nvim_buf_set_option(float_win.buf, 'filetype', filetype)
    api.nvim_buf_set_lines(float_win.buf, 0, -1, false, lines)

    -- Calculate window dimensions
    local max_height = math.floor(api.nvim_get_option('lines') * 0.6)
    local max_width = math.floor(api.nvim_get_option('columns') * 0.7)
    local content_height = #lines
    local content_width = 0
    for _, line in ipairs(lines) do
        content_width = math.max(content_width, fn.strdisplaywidth(line))
    end

    local win_height = math.min(max_height, content_height)
    local win_width = math.min(max_width, content_width + 2) -- +2 for padding/border

    -- Open floating window near the cursor
    local anchor_win = api.nvim_get_current_win()
    local win_opts = vim.lsp.util.make_floating_popup_options(win_width, win_height, M.config.suggestion_float_opts, anchor_win)

    float_win.win = api.nvim_open_win(float_win.buf, true, win_opts) -- `enter=true`
    api.nvim_win_set_option(float_win.win, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
    api.nvim_win_set_option(float_win.win, 'cursorline', true) -- Highlight line in popup

    -- Set mappings for accepting/dismissing (only while float is open)
    api.nvim_buf_set_keymap(
        float_win.buf,
        'n',
        '<CR>',
        '<Cmd>lua require("next_edit_suggestion").accept_suggestion()<CR>',
        { noremap = true, silent = true, nowait = true }
    )
    api.nvim_buf_set_keymap(
        float_win.buf,
        'n',
        '<Esc>',
        '<Cmd>lua require("next_edit_suggestion").dismiss_suggestion()<CR>',
        { noremap = true, silent = true, nowait = true }
    )
    api.nvim_buf_set_keymap(
        float_win.buf,
        'n',
        'q',
        '<Cmd>lua require("next_edit_suggestion").dismiss_suggestion()<CR>',
        { noremap = true, silent = true, nowait = true }
    )

    notify('Suggestion ready. Press <CR> to accept, <Esc> or q to dismiss.')
end

-- --- Public Functions / Commands ---

-- Main function to trigger the suggestion process
function M.get_suggestion()
    local context = gather_context()
    if not context then
        return
    end -- Error already notified

    local payload = construct_request_payload(context)
    if not payload then
        notify('Failed to construct request payload.', vim.log.levels.ERROR)
        return
    end

    -- Store context needed for applying the suggestion
    last_suggestion.start_line = context.snippet_start_line_1based - 1 -- Store 0-indexed
    last_suggestion.end_line = context.snippet_end_line_1based - 1 -- Store 0-indexed (exclusive for replace)

    -- Make the async call
    call_suggestion_api(payload, function(err, response_text)
        if err then
            -- Error already notified by call_suggestion_api
            last_suggestion = { code = nil, start_line = nil, end_line = nil, cursor_pos = nil } -- Reset
            return
        end

        -- Need to run parsing and display on the main thread
        vim.schedule(function()
            local suggested_lines = parse_response(response_text)
            if suggested_lines then
                last_suggestion.code = suggested_lines
                display_suggestion(suggested_lines)
            else
                notify('Failed to parse suggestion.', vim.log.levels.WARN)
                last_suggestion = { code = nil, start_line = nil, end_line = nil, cursor_pos = nil } -- Reset
            end
        end)
    end)
end

-- Function to accept the displayed suggestion
function M.accept_suggestion()
    if not last_suggestion.code or not last_suggestion.start_line or not last_suggestion.end_line then
        notify('No suggestion available to accept.', vim.log.levels.WARN)
        close_float_win()
        return
    end

    local bufnr = api.nvim_get_current_buf()

    -- Check if buffer changed significantly since request? (Optional, complex)

    notify('Applying suggestion...')

    -- Ensure start/end lines are valid
    local line_count = api.nvim_buf_line_count(bufnr)
    if last_suggestion.start_line < 0 or last_suggestion.end_line >= line_count or last_suggestion.start_line > last_suggestion.end_line + 1 then
        notify('Buffer changed too much, cannot apply suggestion safely.', vim.log.levels.ERROR)
        close_float_win()
        last_suggestion = { code = nil, start_line = nil, end_line = nil, cursor_pos = nil }
        return
    end

    -- Replace the lines corresponding to the original snippet
    api.nvim_buf_set_lines(bufnr, last_suggestion.start_line, last_suggestion.end_line + 1, false, last_suggestion.code)

    -- Move cursor to the position indicated by <|cursor|>
    if last_suggestion.cursor_pos then
        local final_cursor_line = last_suggestion.start_line + last_suggestion.cursor_pos.line + 1 -- Convert to 1-based
        local final_cursor_col = last_suggestion.cursor_pos.col -- Already 0-based col index
        api.nvim_win_set_cursor(0, { final_cursor_line, final_cursor_col })
    else
        -- Fallback cursor position if marker wasn't found
        api.nvim_win_set_cursor(0, { last_suggestion.start_line + 1, 0 })
    end

    close_float_win()
    notify('Suggestion applied.')

    -- Clear the stored suggestion
    last_suggestion = { code = nil, start_line = nil, end_line = nil, cursor_pos = nil }
end

-- Function to dismiss the suggestion window
function M.dismiss_suggestion()
    close_float_win()
    notify('Suggestion dismissed.')
    -- Clear the stored suggestion
    last_suggestion = { code = nil, start_line = nil, end_line = nil, cursor_pos = nil }
end

-- --- Setup ---

function M.setup(user_config)
    M.config = vim.tbl_deep_extend('force', M.config, user_config or {})

    -- Define a user command
    api.nvim_create_user_command('NextEditSuggestion', function()
        M.get_suggestion()
    end, { desc = 'Get the next edit suggestion from API' })

    -- Example keymap (optional)
    -- vim.keymap.set('n', '<leader>nes', '<Cmd>NextEditSuggestion<CR>', { noremap = true, silent = true, desc = "Next Edit Suggest" })

    notify('Next Edit Suggestion setup complete. Use :NextEditSuggestion', vim.log.levels.INFO)
end

return M
