local M = {}

local function nop() end

function M.execute(async_func, callback, ...)
    local thread = coroutine.create(async_func)

    callback = callback or nop

    local function cont(...)
        local ok, next_or_res = coroutine.resume(thread, ...)
        assert(ok, next_or_res)

        if coroutine.status(thread) == 'dead' then
            callback(next_or_res)
        else
            next_or_res(cont)
        end
    end

    cont(...)
end

local Awaitable = function(obj, key)
    assert(key == 'await', key)
    return function()
        return M.await(obj)
    end
end

-- make function(p1, ..., pN, callback) awaitable
-- return a callable and awaitable object
function M.async(async_func)
    return function(...)
        local params = { ... }
        return setmetatable({}, {
            __call = function(_, cont)
                table.insert(params, cont)
                async_func(unpack(params))
            end,
            __index = Awaitable,
        })
    end
end

M.sleep = M.async(function(ms, callback)
    vim.defer_fn(callback, ms)
end)

local join = function(...)
    local thunks = { ... }
    local len = vim.tbl_count(thunks)
    local done = 0
    local acc = {}

    local thunk = function(cont)
        if len == 0 then
            return cont()
        end
        for i, tk in ipairs(thunks) do
            local callback = function(...)
                acc[i] = { ... }
                done = done + 1
                if done == len then
                    cont(unpack(acc))
                end
            end
            tk(callback)
        end
    end
    return thunk
end

function M.await_all(...)
    return M.await(join(...))
end

function M.await(defer)
    return coroutine.yield(defer)
end

M.schedule = M.async(vim.schedule)

function M.wrap(async_func)
    return function(...)
        M.execute(async_func, nil, ...)
    end
end

-- no return values
function M.run(async_func, ...)
    M.wrap(async_func)(...)
end

function M.uv()
    return require('dotvim.util.async.uv')
end

M.api = setmetatable({}, {
    __index = function(t, key)
        t[key] = function(...)
            if vim.in_fast_event() then
                M.schedule().await()
            end
            return vim.api[key](...)
        end
        return t[key]
    end,
})

M.ui = setmetatable({}, {
    __index = function(t, key)
        local fn = vim.ui[key]
        t[key] = M.async(function(...)
            local params = { ... }
            local callback = params[#params]
            params[#params] = function(...)
                callback(...)
            end
            fn(unpack(params))
        end)
        return t[key]
    end,
})

M.system = M.async(vim.system)

return M
