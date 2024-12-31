local Session = require('dotvim.lib.floaterm.session')
local UI = require('dotvim.lib.floaterm.ui')

---@alias FloatermId number

---@class Floaterm
---@field id FloatermId
---@field private ui FloatermUI
---@field private current_session? FloatermSession
---@field private sessions table<SessionId, FloatermSession>
---@field private _next_session_id SessionId
local M = {}

vim.g.next_floaterm_id = vim.g.next_floaterm_id or 1

---@return FloatermId
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

    term:_subscribe_events()

    return term
end

---@private
function M:_subscribe_events()
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FloatermSessionClose' .. self.id,
        callback = function(args)
            local session_id = args.data.id
            self:_on_session_closed(session_id)
        end,
    })
    vim.api.nvim_create_autocmd('User', {
        pattern = 'FloatermSessionError' .. self.id,
        callback = function(args)
            local session_id = args.data.id
            local code = args.data.code
            self:_on_session_error(session_id, code)
        end,
    })

    vim.api.nvim_create_autocmd('WinResized', {
        callback = function()
            self:update()
        end,
    })
end

---@private
---@return SessionId
function M:_new_session_id()
    local sid = self._next_session_id
    self._next_session_id = sid + 1
    return sid
end

---@private
function M:_create_session()
    local sid = self:_new_session_id()
    local session = Session.new(sid, self.id)
    self.sessions[sid] = session
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

    if self.current_session and not opts.force_new then
        self:_update()
        return
    end

    local new_session = self:_create_session()
    self.current_session = new_session
    self:_update()

    new_session:init()
end

---@private
function M:_format_sessions()
    local session_ids = vim.tbl_keys(self.sessions)
    table.sort(session_ids)
    local icons = vim.iter(session_ids)
        :map(function(sid)
            local icon = self.current_session.id == sid and '●' or '○'
            local sess = self.sessions[sid]
            if sess.code ~= nil and sess.code ~= 0 then
                icon = '✗'
            end
            return icon
        end)
        :totable()
    if #icons < 2 then
        return ''
    end
    local s = table.concat(icons, ' ')

    return string.format(' %s ', s)
end

-- show the current session if ui is not hidden
function M:update()
    if self.ui:hidden() then
        return
    end
    self:_update()
end

-- open the ui and show the current session
---@private
function M:_update()
    if not self.current_session then
        return
    end
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
function M:_set_current(sid)
    self.current_session = self.sessions[sid]
    self:update()
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

---@private
---@param session_id SessionId
---@param code number
function M:_on_session_error(session_id, code)
    if not self.sessions[session_id] then
        return
    end
    self.sessions[session_id].code = code

    self:update()
end

---@private
---@param session_id SessionId
function M:_fallback(session_id)
    return self:_next_session(session_id, false) or self:_prev_session(session_id, false)
end

---@private
---@param session_id SessionId
function M:_on_session_closed(session_id)
    self.sessions[session_id] = nil

    -- other session closed, just remove it and update ui if needed
    if not self.current_session or session_id ~= self.current_session.id then
        self:update()
        return
    end

    -- current session closed, fallback to next or prev session
    local fallback = self:_fallback(session_id)
    -- no session left
    if not fallback then
        self.current_session = nil
        return
    end

    self:_set_current(fallback)

    -- idk why, but the delay is needed, otherwise the fallback session won't start insert
    vim.defer_fn(function()
        if not self.current_session or not self.current_session:is_valid() then
            return
        end
        self.current_session:prompt()
    end, 10)
end

---@param cycle? boolean
function M:next_session(cycle)
    local sid = self:_next_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self:_set_current(sid)
end

---@param cycle? boolean
function M:prev_session(cycle)
    local sid = self:_prev_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self:_set_current(sid)
end

return M
