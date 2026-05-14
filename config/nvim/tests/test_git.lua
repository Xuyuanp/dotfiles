local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local T = new_set()

-- Create a throwaway git repo under $TMPDIR. Returns the canonical (realpath)
-- repo root so tests can compare string equality without symlink surprises
-- (e.g. /var -> /private/var on macOS).
local function make_repo()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, 'p')
    local function git(args)
        local res = vim.system(vim.list_extend({ 'git', '-C', tmp }, args)):wait()
        assert(res.code == 0, (res.stderr or '') .. (res.stdout or ''))
        return res
    end
    git({ 'init', '-q' })
    git({ 'config', 'user.email', 't@t' })
    git({ 'config', 'user.name', 't' })
    local tracked = tmp .. '/tracked.txt'
    vim.fn.writefile({ 'x' }, tracked)
    git({ 'add', 'tracked.txt' })
    git({ 'commit', '-qm', 'init' })

    local canonical = vim.uv.fs_realpath(tmp) or tmp
    return tmp, canonical
end

local function realpath(p)
    return p and (vim.uv.fs_realpath(p) or p)
end

-- =============================================================================
-- M.root()
-- =============================================================================

T['root()'] = new_set()

T['root()']['resolves repo root from the repo root directory itself'] = function()
    local tmp, canonical = make_repo()
    local git = require('dotvim.util.git')

    -- When the input path is the repo root (a directory), the helper must
    -- still return the repo root -- not error out because :h of the root
    -- moves into a parent that is outside any git repo.
    eq(realpath(git.root(tmp)), canonical)
end

T['root()']['resolves repo root from a subdirectory'] = function()
    local tmp, canonical = make_repo()
    vim.fn.mkdir(tmp .. '/sub', 'p')

    local git = require('dotvim.util.git')
    eq(realpath(git.root(tmp .. '/sub')), canonical)
end

T['root()']['resolves repo root from a file inside the repo'] = function()
    local tmp, canonical = make_repo()

    local git = require('dotvim.util.git')
    eq(realpath(git.root(tmp .. '/tracked.txt')), canonical)
end

T['root()']['returns nil for paths outside any git repo'] = function()
    local tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, 'p')

    local git = require('dotvim.util.git')
    eq(git.root(tmp), nil)
end

T['root()']['returns nil for non-existent paths'] = function()
    local git = require('dotvim.util.git')
    eq(git.root('/this/path/does/not/exist/xyzzy'), nil)
end

return T
