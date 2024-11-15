local Copilot = require('CopilotChat.copilot')
local async = require('plenary.async')
local async_util = require('plenary.async.util')

local M = {}

local prompt_template = [[
Please function as a Unix Shell Command Generator.
Provide only the shell command needed to accomplish the following task,
without any additional explanation or formatting.
Do not use markdown or any extra characters, just the shell command itself.
My task is:
%s
]]

local command = async.void(function(ev)
    local copilot = Copilot()
    if ev.bang then
        local log = require('plenary.log')
        log.new({ level = 'fatal' }, true)
    end

    local prompt = prompt_template:format(ev.args)
    local rsp = copilot:ask(prompt)
    async_util.scheduler()

    if ev.bang then
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
