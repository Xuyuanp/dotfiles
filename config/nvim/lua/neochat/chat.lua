local Popup = require('nui.popup')
local Layout = require('nui.layout')
local event = require('nui.utils.autocmd').event

local Chat = {}

function Chat.new()
    local popup_chat = Popup({
        border = {
            style = 'rounded',
            text = {
                top = 'Chat',
                top_align = 'center',
            },
        },
        buf_options = {
            filetype = 'markdown',
            readonly = true,
        },
        win_options = {
            wrap = true,
        },
    })

    local popup_input = Popup({
        border = {
            style = 'rounded',
            text = {
                top = 'Input',
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
            Layout.Box(popup_chat, { size = '75%' }),
            Layout.Box(popup_input, { size = '25%' }),
        }, { dir = 'col' })
    )

    local chat = setmetatable({
        hidden = false,
        layout = layout,
        popup_chat = popup_chat,
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
        -- focus on chat
        vim.api.nvim_set_current_win(self.popup_chat.winid)
    end, { noremap = false })

    self.popup_chat:map('n', '<Down>', function()
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
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, 0, -1, false, {})
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
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, { '# @You:' })
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, input)
    -- add new line
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, { '' })

    table.insert(self.messages, {
        role = 'user',
        content = vim.fn.join(input, '\n'),
    })
end

function Chat:on_submit()
    local lines = self:get_input()
    if not lines then
        return
    end

    -- clear input
    self:clear_input()

    self:append_input(lines)

    self:perform_request()
end

function Chat:perform_request()
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, { '# @ChatGPT:' })
    -- newline
    vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, { '' })
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

        if not data then
            vim.schedule(function()
                vim.api.nvim_buf_set_lines(self.popup_chat.bufnr, -1, -1, false, { '' })
            end)
            return
        end

        self.messages[#self.messages].content = self.messages[#self.messages].content .. data

        vim.schedule(function()
            local lines = vim.api.nvim_buf_get_lines(self.popup_chat.bufnr, 0, -1, false)
            local row = #lines - 1
            local col = lines[#lines]:len()
            vim.api.nvim_buf_set_text(self.popup_chat.bufnr, row, col, row, col, vim.split(data, '\n', { plain = true }))
        end)
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

return Chat
