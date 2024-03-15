--[[
Example:

--]]
local uv = vim.uv
local a = require('dotvim.util.async')

local M = {}

local function add(func)
    M[func] = a.async(uv[func])
end

---[[ stolen from plenary start

add('close') -- close a handle

-- filesystem operations
add('fs_open')
add('fs_read')
add('fs_close')
add('fs_unlink')
add('fs_write')
add('fs_mkdir')
add('fs_mkdtemp')
-- 'fs_mkstemp',
add('fs_rmdir')
add('fs_scandir')
add('fs_stat')
add('fs_fstat')
add('fs_lstat')
add('fs_rename')
add('fs_fsync')
add('fs_fdatasync')
add('fs_ftruncate')
add('fs_sendfile')
add('fs_access')
add('fs_chmod')
add('fs_fchmod')
add('fs_utime')
add('fs_futime')
-- 'fs_lutime',
add('fs_link')
add('fs_symlink')
add('fs_readlink')
add('fs_realpath')
add('fs_chown')
add('fs_fchown')
-- 'fs_lchown',
add('fs_copyfile')

M.fs_opendir = a.async(function(path, entries, callback)
    return uv.fs_opendir(path, callback, entries)
end)

add('fs_readdir')
add('fs_closedir')
add('fs_statfs')

-- stream
add('shutdown')
add('listen')
-- add('read_start', 2) -- do not do this one, the callback is made multiple times
add('write')
add('write2')
add('shutdown')

-- tcp
add('tcp_connect')
-- 'tcp_close_reset',

-- pipe
add('pipe_connect')

-- udp
add('udp_send')
add('udp_recv_start')

-- fs event (wip make into async await event)
-- fs poll event (wip make into async await event)

-- dns
add('getaddrinfo')
add('getnameinfo')

---]] copy from plenary end

function M.read_file(path)
    local err, fd = M.fs_open(path, 'r', 438).await()
    if err then
        return err
    end

    local err, stat = M.fs_fstat(fd).await()
    if err then
        M.fs_close(fd).await()
        return err
    end

    local err, data = M.fs_read(fd, stat.size, 0).await()
    if err then
        M.fs_close(fd).await()
        return err
    end

    M.fs_close(fd).await()

    return nil, data
end

-- require('dotvim.util.async.uv').example_read_file('/path/to/file')
M.example_read_file = a.wrap(function(path)
    local start = M.now() -- call sync function

    local err, fd = M.fs_open(path, 'r', 438).await()
    assert(not err, err)

    local err, stat = M.fs_fstat(fd).await()
    assert(not err, err)

    local err, data = M.fs_read(fd, stat.size, 0).await()
    assert(not err, err)

    print(data)

    local err = M.fs_close(fd).await()
    assert(not err, err)

    print('cost: ', M.now() - start, 'ms')
end)

return setmetatable(M, {
    __index = uv,
})
