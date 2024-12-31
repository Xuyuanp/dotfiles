local Session = require('dotvim.lib.floaterm.session')
local UI = require('dotvim.lib.floaterm.ui')

---@class Floaterm
---@field id number
---@field private ui FloatermUI
---@field private current_session? FloatermSession
---@field private sessions table<SessionId, FloatermSession>
---@field private _next_session_id SessionId
local M = {}

vim.g.next_floaterm_id = vim.g.next_floaterm_id or 1

local function gen_term_id()
    local term_id = vim.g.next_floaterm_id
    vim.g.next_floaterm_id = term_id + 1
    return term_id
end

---@return Floaterm
function M.new()
    local term = setmetatable({
        id = gen_term_id(),
        sessions = {},
        ui = UI.new(),
        _next_session_id = 1,
    }, {
        __index = M,
    })

    term:subscribe_events()

    return term
end

---@private
function M:subscribe_events()
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FloatermSessionClose' .. self.id,
        callback = function(args)
            local session_id = args.data.id
            self:on_session_closed(session_id)
        end,
    })
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FloatermSessionError' .. self.id,
        callback = function(args)
            local session_id = args.data.id
            local code = args.data.code
            self:on_session_error(session_id, code)
        end,
    })

    vim.api.nvim_create_autocmd('WinResized', {
        callback = function()
            self:update()
        end,
    })
end

---@private
function M:_new_session_id()
    local sid = self._next_session_id
    self._next_session_id = sid + 1
    return sid
end

---@private
function M:_create_session()
    local session = Session.new(self:_new_session_id(), self.id)
    self.sessions[session.id] = session
    return session
end

---@class FloatermOpenOpts
---@field force_new? boolean

---@param opts? FloatermOpenOpts
function M:open(opts)
    opts = opts or {}

    -- cleanup invalid session
    if self.current_session and not self.current_session:is_valid() then
        self.sessions[self.current_session.id] = nil
        self.current_session = nil
    end

    local new_session
    if not self.current_session or opts.force_new then
        new_session = self:_create_session()
        self.current_session = new_session
    end

    self:_update()

    if new_session then
        -- we should init session after the window is opened
        new_session:init()
    end
end

---@private
function M:_format_sessions()
    local icons = {}
    for _, sess in pairs(self.sessions or {}) do
        local icon = self.current_session.id == sess.id and '●' or '○'
        if sess.code ~= nil and sess.code ~= 0 then
            icon = '✗'
        end
        table.insert(icons, icon)
    end
    if #icons < 2 then
        return ''
    end
    return string.format(' %s ', table.concat(icons, ' '))
end

function M:update()
    if self.ui:hidden() then
        return
    end
    self:_update()
end

---@private
function M:_update()
    self.ui:show(self.current_session.bufnr, {
        title = self:_format_sessions(),
        title_pos = 'center',
    })
end

function M:hidden()
    return self.ui:hidden() or not self.ui:is_valid()
end

function M:hide()
    if self:hidden() then
        return
    end
    self:_hide()
end

---@private
function M:_hide()
    self.ui:hide()
end

function M:toggle()
    if self:hidden() then
        self:open()
    else
        self:hide()
    end
end

---@private
function M:_current_session_id()
    return self.current_session and self.current_session.id
end

---@private
---@param session_id SessionId
---@param cycle? boolean
---@return number?
function M:_next_session(session_id, cycle)
    local session_ids = vim.tbl_keys(self.sessions)
    if #session_ids < 1 then
        return
    end
    table.sort(session_ids)
    for _, sid in ipairs(session_ids) do
        if sid > session_id then
            return sid
        end
    end

    if not cycle then
        return
    end

    local first = session_ids[1]
    if first == session_id then
        return
    end
    return first
end

---@private
---@param session_id SessionId
---@param cycle? boolean
---@return number?
function M:_prev_session(session_id, cycle)
    local session_ids = vim.tbl_keys(self.sessions)
    if #session_ids < 1 then
        return
    end
    table.sort(session_ids, function(a, b)
        return a > b
    end)

    for _, sid in ipairs(session_ids) do
        if sid < session_id then
            return sid
        end
    end

    if not cycle then
        return
    end

    local first = session_ids[1]
    if first == session_id then
        return
    end
    return first
end

function M:on_session_error(session_id, code)
    if code == 0 then
        return
    end
    if not self.sessions[session_id] then
        return
    end
    self.sessions[session_id].code = code

    self:update()
end

---@private
---@param session_id SessionId
function M:on_session_closed(session_id)
    self.sessions[session_id] = nil

    -- other session closed, just remove it and update ui if needed
    if self.current_session and session_id == self.current_session.id then
        -- current session closed, fallback to next or prev session
        local fallback = self:_next_session(session_id, false) or self:_prev_session(session_id, false)
        -- no session left
        if not fallback then
            self.current_session = nil
            return
        end

        self.current_session = self.sessions[fallback]
    end

    self:update()
end

---@param cycle? boolean
function M:next_session(cycle)
    local sid = self:_next_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self.current_session = self.sessions[sid]
    self:update()
end

---@param cycle? boolean
function M:prev_session(cycle)
    local sid = self:_prev_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self.current_session = self.sessions[sid]
    self:update()
end

return M
