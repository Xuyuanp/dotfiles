local vim = vim
local vfn = vim.fn

local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
local std_data_path = vfn.stdpath('data')
local lazypath = std_data_path .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        lazyrepo,
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

if vfn.has('osx') then
    vfn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.8')
end

local M = {}

local function get_plugins()
    return {
        { 'folke/lazy.nvim', version = '*' },
        { import = 'dotvim.plugins' },
    }
end

function M.setup()
    local plugins = get_plugins()
    local opts = {
        performance = {
            rtp = {
                disabled_plugins = {
                    'gzip',
                    'matchit',
                    'matchparen',
                    'netrwPlugin',
                    'tarPlugin',
                    'tohtml',
                    'tutor',
                    'zipPlugin',
                },
            },
        },
    }
    require('lazy').setup(plugins, opts)
end

return M
