---@class FloatermUI
---@field private winnr? number
---@field private _hidden boolean
local M = {}

---@return FloatermUI
function M.new()
    return setmetatable({
        _hidden = true,
    }, { __index = M })
end

local function get_size()
    local win_width, win_height = vim.o.columns, vim.o.lines

    local width = math.floor(win_width * 0.8)
    local height = math.floor(win_height * 0.8)
    local row = math.floor((win_height - height) / 2)
    local col = math.floor((win_width - width) / 2)

    return width, height, row, col
end

function M:get_config(opts)
    local width, height, row, col = get_size()

    return vim.tbl_deep_extend('force', {
        style = 'minimal',
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        border = 'rounded',
    }, opts or {})
end

---@private
---@return number?
function M:bufnr()
    return self.winnr and vim.api.nvim_win_get_buf(self.winnr)
end

function M:show(bufnr, opts)
    if not self._hidden and self:is_valid() then
        if bufnr ~= self:bufnr() then
            vim.api.nvim_win_set_buf(self.winnr, bufnr)
        end
        self:update(opts)
        self._hidden = false
        return
    end

    local config = self:get_config(opts)
    self.winnr = vim.api.nvim_open_win(bufnr, true, config)
    self._hidden = false
end

---@return boolean
function M:hidden()
    return self._hidden
end

function M:is_valid()
    return self.winnr and vim.api.nvim_win_is_valid(self.winnr)
end

function M:hide()
    self._hidden = true
    vim.api.nvim_win_hide(self.winnr)
    self.winnr = nil
end

function M:update(opts)
    if not self:is_valid() then
        return
    end
    local config = self:get_config(opts)
    vim.api.nvim_win_set_config(self.winnr, config)
end

return M
