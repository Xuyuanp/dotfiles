local M = {}

local function osc(lines)
    local content = table.concat(lines, '\n')
    local encoded = vim.base64.encode(content)
    local escaped = string.format('%s]52;c;%s%s', string.char(0x1b), encoded, string.char(0x07))
    return escaped
end

function M.copy(lines, _)
    local content = osc(lines)
    local out = vim.env.SSH_TTY or '/dev/fd/2'
    vim.fn.writefile({ content }, out, 'b')
end

function M.paste()
    local content = vim.fn.getreg('')
    if not content then
        return
    end
    return { vim.fn.split(content, '\n'), vim.fn.getregtype('') }
end

return M
