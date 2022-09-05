local M = {}

function M.copy(lines, _)
    vim.fn.system('osc52-yank', table.concat(lines, '\n'))
end

function M.paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
end

return M
