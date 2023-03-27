local Popup = require('nui.popup')
local Layout = require('nui.layout')
local event = require('nui.utils.autocmd').event
local NuiText = require('nui.text')

local function You()
    -- TODO: add highlight group
    return NuiText('# @You:', 'Keyword')
end

local function ChatGPT()
    -- TODO: add highlight group
    return NuiText('# @ChatGPT:', 'Function')
end

local Chat = {}

function Chat.new()
    local popup_conversation = Popup({
        border = {
            style = 'rounded',
            text = {
                top = '[Conversation]',
                top_align = 'center',
            },
        },
        buf_options = {
            filetype = 'markdown',
            readonly = true,
        },
        win_options = {
            wrap = true,
            conceallevel = 1,
        },
    })

    local popup_input = Popup({
        border = {
            style = 'rounded',
            text = {
                top = '[Input]',
                top_align = 'center',
                bottom = '<CR>: submit, <S-CR>: add newline, <C-CR>: new chat',
                bottom_align = 'center',
            },
        },
        enter = true,
        buf_options = {
            filetype = 'markdown',
        },
        win_options = {
            wrap = true,
        },
    })

    local layout = Layout(
        {
            position = '50%',
            size = {
                width = '60%',
                height = '80%',
            },
        },
        Layout.Box({
            Layout.Box(popup_conversation, { size = '75%' }),
            Layout.Box(popup_input, { size = '25%' }),
        }, { dir = 'col' })
    )

    local chat = setmetatable({
        hidden = false,
        layout = layout,
        popup_conversation = popup_conversation,
        popup_input = popup_input,
        messages = {},
    }, { __index = Chat })

    chat:init()

    layout:mount()
    return chat
end

function Chat:init()
    self.popup_input:on({ event.BufWinEnter }, function()
        vim.cmd('startinsert')
    end, { once = true })

    self.popup_input:map('i', '<S-CR>', '<ESC>o', { noremap = true })
    self.popup_input:map('i', '<C-CR>', function()
        self:clear()
    end, { noremap = true })
    self.popup_input:map('i', '<CR>', function()
        self:on_submit()
    end, { noremap = false })

    self.popup_input:map('n', '<Up>', function()
        -- focus on conversation
        vim.api.nvim_set_current_win(self.popup_conversation.winid)
    end, { noremap = false })

    self.popup_conversation:map('n', '<Down>', function()
        -- focus on input
        vim.api.nvim_set_current_win(self.popup_input.winid)
    end, { noremap = false })
end

function Chat:toggle()
    if self.hidden then
        self.layout:show()
    else
        self.layout:hide()
    end
    self.hidden = not self.hidden
end

function Chat:clear()
    self.messages = {}
    vim.api.nvim_buf_set_lines(self.popup_conversation.bufnr, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(self.popup_input.bufnr, 0, -1, false, {})
end

function Chat:clear_input()
    vim.api.nvim_buf_set_lines(self.popup_input.bufnr, 0, -1, false, {})
end

function Chat:get_input()
    local lines = vim.api.nvim_buf_get_lines(self.popup_input.bufnr, 0, -1, false)
    return lines
end

---@param input string[]
function Chat:append_input(input)
    -- send to chat
    local line_count = vim.api.nvim_buf_line_count(self.popup_conversation.bufnr)
    You():render(self.popup_conversation.bufnr, -1, line_count, 0, line_count, 0)
    -- print input
    vim.api.nvim_buf_set_lines(self.popup_conversation.bufnr, -1, -1, false, input)
    -- add two new lines
    vim.api.nvim_buf_set_lines(self.popup_conversation.bufnr, -1, -1, false, { '', '' })

    -- move cursor to the end
    local line_count = vim.api.nvim_buf_line_count(self.popup_conversation.bufnr)
    vim.api.nvim_win_set_cursor(self.popup_conversation.winid, { line_count, 0 })

    table.insert(self.messages, {
        role = 'user',
        content = vim.fn.join(input, '\n'),
    })
end

function Chat:on_submit()
    local lines = self:get_input()
    if not lines or lines[1] == '' then
        return
    end

    -- clear input
    self:clear_input()

    self:append_input(lines)

    ---@diagnostic disable-next-line: param-type-mismatch
    vim.defer_fn(function()
        self:perform_request()
        ---@diagnostic disable-next-line: param-type-mismatch
    end, 800)
end

function Chat:perform_request()
    local line_count = vim.api.nvim_buf_line_count(self.popup_conversation.bufnr)
    ChatGPT():render(self.popup_conversation.bufnr, -1, line_count, 0, line_count, 0)

    -- add newline
    vim.api.nvim_buf_set_lines(self.popup_conversation.bufnr, -1, -1, false, { '' })
    -- move cursor to the end
    local line_count = vim.api.nvim_buf_line_count(self.popup_conversation.bufnr)
    vim.api.nvim_win_set_cursor(self.popup_conversation.winid, { line_count, 0 })

    table.insert(self.messages, {
        role = 'assistant',
        content = '',
    })

    local uv = vim.loop

    local pipe_stdin = uv.new_pipe()
    local pipe_stdout = uv.new_pipe()
    local pipe_stderr = uv.new_pipe()

    assert(pipe_stdin, 'pipe failed')
    assert(pipe_stdout, 'pipe failed')
    assert(pipe_stderr, 'pipe failed')

    local handle
    handle = uv.spawn('python', {
        args = {
            vim.fn.stdpath('config') .. '/scripts/neochat.py',
        },
        stdio = { pipe_stdin, pipe_stdout, pipe_stderr },
    }, function(code, signal)
        print('Exit code: ', code, signal)
        uv.close(pipe_stdout)
        uv.close(pipe_stderr)

        if handle then
            handle:close()
        end
    end)
    assert(handle, 'spawn failed')

    uv.read_start(pipe_stdout, function(err, data)
        assert(not err, err)

        self:on_delta(data)
    end)

    uv.read_start(pipe_stderr, function(err, data)
        assert(not err, err)

        if data then
            print('stderr:', data)
        end
    end)

    uv.write(pipe_stdin, vim.fn.json_encode(self.messages))
    uv.shutdown(pipe_stdin)
end

function Chat:on_delta(data)
    if not data then
        -- output ends, print new line
        data = '\n\n'
    else
        local content = self.messages[#self.messages].content
        self.messages[#self.messages].content = content .. data
    end

    vim.schedule(function()
        local line_count = vim.api.nvim_buf_line_count(self.popup_conversation.bufnr)
        local last_line = vim.api.nvim_buf_get_lines(self.popup_conversation.bufnr, -2, -1, false)[1] or ''
        local row = line_count
        local col = last_line:len()

        local lines = vim.split(data, '\n', { plain = true })
        vim.api.nvim_buf_set_text(self.popup_conversation.bufnr, row - 1, col, row - 1, col, lines)

        row = row + #lines - 1
        if #lines > 1 then
            col = lines[#lines]:len()
        else
            col = col + lines[#lines]:len()
        end

        -- move cursor to the end
        vim.api.nvim_win_set_cursor(self.popup_conversation.winid, { row, col })
    end)
end

return Chat
