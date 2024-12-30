---@alias SessionId number

---@class FloatermSession
---@field id SessionId
---@field bufnr number
---@field term_id number
---@field code? number
local Session = {}

local next_session_id = 1

local function gen_session_id()
    local session_id = next_session_id
    next_session_id = next_session_id + 1
    return session_id
end

---@param term_id number
---@return FloatermSession
function Session.new(term_id)
    local sess = setmetatable({
        id = gen_session_id(),
        bufnr = vim.api.nvim_create_buf(false, true),
        term_id = term_id,
    }, { __index = Session })

    return sess
end

function Session:init()
    vim.api.nvim_buf_call(self.bufnr, function()
        if vim.bo.buftype == 'terminal' then
            return
        end
        local job_id = vim.fn.jobstart({ vim.o.shell }, {
            term = true,
            env = {
                TERM = vim.env.TERM,
            },
            on_exit = function(_, code)
                self:_on_exit(code)
            end,
        })
        vim.b.floaterm_job_id = job_id
        vim.b.floaterm = true
        vim.bo.filetype = 'floaterm'
    end)
end

---@private
---@param code number
function Session:_on_exit(code)
    self.code = code
    vim.api.nvim_exec_autocmds('User', {
        pattern = 'FloatermSessionClose' .. self.term_id,
        data = { id = self.id, bufnr = self.bufnr, code = code },
    })
end

---@return boolean
function Session:is_valid()
    return self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr)
end

return Session
