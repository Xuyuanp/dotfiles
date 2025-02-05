local M = {}

function M:init()
    local group = vim.api.nvim_create_augroup('CodeCompanionFidgetHooks', { clear = true })

    vim.api.nvim_create_autocmd({ 'User' }, {
        pattern = 'CodeCompanionRequestStarted',
        group = group,
        callback = function(args)
            local handle = M:create_progress_handle(args.data)
            M:store_progress_handle(args.data.id, handle)
        end,
    })

    vim.api.nvim_create_autocmd({ 'User' }, {
        pattern = 'CodeCompanionRequestFinished',
        group = group,
        callback = function(args)
            local handle = M:pop_progress_handle(args.data.id)
            if handle then
                M:report_exit_status(handle, args.data)
                handle:finish()
            end
        end,
    })
end

M.handles = {}

function M:store_progress_handle(id, handle)
    M.handles[id] = handle
end

function M:pop_progress_handle(id)
    local handle = M.handles[id]
    M.handles[id] = nil
    return handle
end

function M:create_progress_handle(event)
    local progress = require('fidget.progress')
    return progress.handle.create({
        title = ' Requesting assistance (' .. event.strategy .. ')',
        message = 'In progress...',
        lsp_client = {
            name = M:llm_role_title(event.adapter),
        },
    })
end

function M:llm_role_title(adapter)
    local parts = {}
    table.insert(parts, adapter.formatted_name)
    if adapter.model and adapter.model ~= '' then
        table.insert(parts, '(' .. adapter.model .. ')')
    end
    return table.concat(parts, ' ')
end

function M:report_exit_status(handle, event)
    if event.status == 'success' then
        handle.message = ' Completed'
    elseif event.status == 'error' then
        handle.message = ' Error'
    else
        handle.message = '󰜺 Cancelled'
    end
end

return M
