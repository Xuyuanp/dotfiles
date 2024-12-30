local function get_size()
    local win_width, win_height = vim.o.columns, vim.o.lines

    local width = math.floor(win_width * 0.8)
    local height = math.floor(win_height * 0.8)
    local row = math.floor((win_height - height) / 2)
    local col = math.floor((win_width - width) / 2)

    return width, height, row, col
end

---@class Term
---@field winnr number
---@field bufnr number
---@field private sessions table session_id -> bufnr
---@field private _next_session_id number
local Term = {}

---@return Term
function Term.new()
    local term = setmetatable({}, {
        __index = Term,
    })

    return term
end

---@private
---@return number
function Term:_create_buf()
    local bufnr = vim.api.nvim_create_buf(false, true)

    local session_id = self._next_session_id or 1
    self._next_session_id = session_id + 1

    self.sessions = self.sessions or {}
    self.sessions[session_id] = bufnr

    return bufnr
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

---@private
function Term:_init_term()
    if vim.bo.buftype == 'terminal' then
        return
    end

    local bufnr = self.bufnr
    local job_id = vim.fn.jobstart({ vim.o.shell }, {
        term = true,
        env = {
            TERM = vim.env.TERM,
        },
        on_exit = function(_, code)
            self:on_term_closed(bufnr, code)
        end,
    })
    vim.b.floaterm_job_id = job_id
    vim.b.floaterm = true
    vim.bo.filetype = 'floaterm'
end

---@class FloatermOpenOpts
---@field force_new? boolean

---@param opts? FloatermOpenOpts
function Term:open(opts)
    opts = opts or {}

    if not self.bufnr or not vim.api.nvim_buf_is_valid(self.bufnr) then
        self.bufnr = nil
    end

    if not self.bufnr or opts.force_new then
        self.bufnr = self:_create_buf()
    end

    if not self:hidden() then
        vim.api.nvim_win_set_buf(self.winnr, self.bufnr)
        self:update()
    else
        self.winnr = self:_open_float_window(self.bufnr)
    end

    vim.api.nvim_win_call(self.winnr, function()
        self:_init_term()
        vim.cmd.startinsert()
    end)
end

---@private
function Term:_format_sessions()
    local icons = {}
    for _, bufnr in pairs(self.sessions or {}) do
        local icon = self.bufnr == bufnr and '●' or '○'
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
function Term:_get_session_id(bufnr)
    for session_id, _bufnr in pairs(self.sessions or {}) do
        if bufnr == _bufnr then
            return session_id
        end
    end
end

---@private
function Term:_current_session_id()
    return self:_get_session_id(self.bufnr)
end

---@param bufnr number
---@param code? number
function Term:on_term_closed(bufnr, code)
    local session_id = self:_get_session_id(bufnr)
    if not session_id then
        return
    end
    self:on_session_closed(session_id, code)
end

---@private
---@param session_id number
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
---@param session_id number
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
    local next_session_id = session_ids[idx]
    if next_session_id == session_id then
        return
    end
    return next_session_id
end

---@param session_id number
---@param code? number
function Term:on_session_closed(session_id, code)
    code = code or 0 -- TODO: keep the failed session

    local fallback = self:_next_session(session_id, false) or self:_prev_session(session_id, false)
    local bufnr = self.sessions[session_id]
    self.sessions[session_id] = nil

    if bufnr ~= self.bufnr then
        self:update()
        return
    end

    if not fallback then
        self.winnr = nil
        self.bufnr = nil
        self.sessions = nil
        return
    end

    self.bufnr = self.sessions[fallback]
    self:open()

    vim.defer_fn(function()
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

    self.bufnr = self.sessions[sid]
    self:open()
end

---@param cycle? boolean
function Term:prev_session(cycle)
    local sid = self:_prev_session(self:_current_session_id(), cycle)
    if not sid then
        return
    end

    self.bufnr = self.sessions[sid]
    self:open()
end

return Term
