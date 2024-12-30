local Session = require('dotvim.lib.floaterm.session')

local function get_size()
    local win_width, win_height = vim.o.columns, vim.o.lines

    local width = math.floor(win_width * 0.8)
    local height = math.floor(win_height * 0.8)
    local row = math.floor((win_height - height) / 2)
    local col = math.floor((win_width - width) / 2)

    return width, height, row, col
end

---@class Term
---@field id number
---@field winnr number
---@field current_session? FloatermSession
---@field private sessions table<SessionId, FloatermSession>
---@field private _next_session_id SessionId
local Term = {}

local next_term_id = 1

local function gen_term_id()
    local term_id = next_term_id
    next_term_id = next_term_id + 1
    return term_id
end

---@return Term
function Term.new()
    local term = setmetatable({
        id = gen_term_id(),
        sessions = {},
    }, {
        __index = Term,
    })

    term:subscribe_session_close()

    return term
end

---@private
function Term:subscribe_session_close()
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FloatermSessionClose' .. self.id,
        callback = function(args)
            local session_id = args.data.id
            local code = args.data.code
            self:on_session_closed(session_id, code)
        end,
    })
end

---@private
function Term:_open_float_window(bufnr, opts)
    opts = opts or {}

    local width, height, row, col = get_size()

    local win_opts = {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = 'rounded',
        title = self:_format_sessions(),
        title_pos = 'center',
    }
    local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)

    return winnr
end

---@class FloatermOpenOpts
---@field force_new? boolean

---@param opts? FloatermOpenOpts
function Term:open(opts)
    opts = opts or {}

    if self.current_session and not self.current_session:is_valid() then
        self.sessions[self.current_session.id] = nil
        self.current_session = nil
    end

    local new_session
    if not self.current_session or opts.force_new then
        new_session = Session.new(self.id)
        self.sessions[new_session.id] = new_session
        self.current_session = new_session
    end

    if not self:hidden() then
        vim.api.nvim_win_set_buf(self.winnr, self.current_session.bufnr)
        self:update()
    else
        self.winnr = self:_open_float_window(self.current_session.bufnr)
    end

    if new_session then
        -- we should call init after the window is opened
        new_session:init()
    end

    vim.api.nvim_win_call(self.winnr, function()
        vim.cmd.startinsert()
    end)
end

---@private
function Term:_format_sessions()
    local icons = {}
    for _, sess in pairs(self.sessions or {}) do
        local icon = self.current_session.id == sess.id and '●' or '○'
        table.insert(icons, icon)
    end
    if #icons == 1 then
        return ''
    end
    return ' ' .. table.concat(icons, ' ') .. ' '
end

function Term:update()
    if self:hidden() then
        return
    end

    local width, height, row, col = get_size()
    vim.api.nvim_win_set_config(self.winnr, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        title = self:_format_sessions(),
        title_pos = 'center',
    })
end

function Term:hidden()
    return not self.winnr or not vim.api.nvim_win_is_valid(self.winnr)
end

function Term:hide()
    if self:hidden() then
        return
    end
    vim.api.nvim_win_hide(self.winnr)
end

function Term:toggle()
    if self:hidden() then
        self:open()
    else
        self:hide()
    end
end

---@private
function Term:_current_session_id()
    return self.current_session and self.current_session.id
end

---@private
---@param session_id SessionId
---@param cycle? boolean
---@return number?
function Term:_next_session(session_id, cycle)
    local session_ids = vim.tbl_keys(self.sessions)
    if #session_ids < 2 then
        return
    end
    table.sort(session_ids)
    local idx
    for i, sid in ipairs(session_ids) do
        if sid == session_id then
            idx = i
            break
        end
    end
    if idx == #session_ids then
        if not cycle then
            return
        end
        idx = 1
    else
        idx = idx + 1
    end
    local next_session_id = session_ids[idx]
    if next_session_id == session_id then
        return
    end
    return next_session_id
end

---@private
---@param session_id SessionId
---@param cycle? boolean
---@return number?
function Term:_prev_session(session_id, cycle)
    local session_ids = vim.tbl_keys(self.sessions)
    if #session_ids < 2 then
        return
    end
    table.sort(session_ids)
    local idx
    for i, sid in ipairs(session_ids) do
        if sid == session_id then
            idx = i
            break
        end
    end
    if idx == 1 then
        if not cycle then
            return
        end
        idx = #session_ids
    else
        idx = idx - 1
    end
    local prev_session_id = session_ids[idx]
    if prev_session_id == session_id then
        return
    end
    return prev_session_id
end

---@param session_id SessionId
---@param code? number
function Term:on_session_closed(session_id, code)
    code = code or 0 -- TODO: keep the failed session

    local fallback = self:_next_session(session_id, false) or self:_prev_session(session_id, false)
    self.sessions[session_id] = nil

    if self.current_session and session_id ~= self.current_session.id then
        self:update()
        return
    end

    if not fallback then
        self.winnr = nil
        self.current_session = nil
        self.sessions = {}
        return
    end

    self.current_session = self.sessions[fallback]
    self:open()

    vim.defer_fn(function()
        if self:hidden() then
            return
        end
        vim.api.nvim_win_call(self.winnr, function()
            vim.cmd.startinsert()
        end)
    end, 10)
end

---@param cycle? boolean
function Term:next_session(cycle)
    local sid = self:_next_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self.current_session = self.sessions[sid]
    self:open()
end

---@param cycle? boolean
function Term:prev_session(cycle)
    local sid = self:_prev_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self.current_session = self.sessions[sid]
    self:open()
end

return Term
