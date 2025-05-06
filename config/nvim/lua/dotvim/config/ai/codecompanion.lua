local M = {}

local handles = {}

local function store_progress_handle(id, handle)
    handles[id] = handle
end

local function pop_progress_handle(id)
    local handle = handles[id]
    handles[id] = nil
    return handle
end

local function create_progress_handle(event)
    local progress = require('fidget.progress')
    return progress.handle.create({
        title = ' Requesting assistance (' .. event.strategy .. ')',
        message = 'Thinking...',
        lsp_client = {
            name = M.format_adapter(event.adapter),
        },
    })
end

local function report_exit_status(handle, event)
    if event.status == 'success' then
        handle.message = ' Completed'
    elseif event.status == 'error' then
        handle.message = ' Error'
    else
        handle.message = '󰜺 Cancelled'
    end
end

function M.init_progress()
    local group = vim.api.nvim_create_augroup('dotvim.codecompanion.progress', { clear = true })

    vim.api.nvim_create_autocmd({ 'User' }, {
        pattern = 'CodeCompanionRequest*',
        group = group,
        callback = function(args)
            if args.data.strategy == 'nes' then
                return
            end
            if args.match == 'CodeCompanionRequestStarted' then
                local handle = create_progress_handle(args.data)
                store_progress_handle(args.data.id, handle)
            elseif args.match == 'CodeCompanionRequestFinished' then
                local handle = pop_progress_handle(args.data.id)
                if handle then
                    report_exit_status(handle, args.data)
                    handle:finish()
                end
            else
                -- not yet
            end
        end,
    })
end

function M.format_adapter(adapter)
    local formatted = adapter.formatted_name
    formatted = (adapter.icon or '') .. ' ' .. formatted
    local model = adapter.model or adapter.parameters and adapter.parameters.model
    if model then
        if type(model) == 'function' then
            model = model()
        end
        formatted = formatted .. '@' .. model
    end
    return formatted
end

return M
