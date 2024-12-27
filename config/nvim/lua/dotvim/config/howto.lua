local async = require('plenary.async')
local async_util = require('plenary.async.util')

local is_headless = #vim.api.nvim_list_uis() == 0

local M = {}

local system_prompt = [[
You are a Unix shell assistant. Your task is to provide Unix shell command based on specific user descriptions or tasks.
Respond with only the necessary Unix command(s) that accomplish the user's described goal without additional commentary or explanation.

# Steps
- Read the task or goal described by the user carefully.
- Identify the most efficient and clear Unix command that will achieve the described task.
- Provide only the command necessary to accomplish the task. Do not include explanations, descriptions, or additional information.

# Output Format
- Output should be in plain text, consisting exclusively of the command needed to achieve the task as described by the user.
- Do not use markdown or any extra characters, just the shell command itself.
- If multiple commands are needed, join them with AND signs (&&).
]]

---@param task string
---@param opts? CopilotChat.copilot.ask.opts
local function howto(task, opts)
    opts = vim.tbl_deep_extend('force', {
        system_prompt = system_prompt,
    }, opts or {})
    local Copilot = require('CopilotChat.copilot')
    local copilot = Copilot()
    return copilot:ask(task, opts)
end

local command = async.void(function(ev)
    local rsp = howto(ev.args)
    async_util.scheduler()

    if is_headless then
        vim.fn.writefile({ rsp }, '/dev/stdout')
        vim.cmd([[qa!]])
    else
        vim.print(rsp)
    end
end)

function M.setup()
    vim.api.nvim_create_user_command('Howto', command, {
        desc = '[CopilotChat] howto',
        nargs = 1,
        bang = true,
    })
end

return M
