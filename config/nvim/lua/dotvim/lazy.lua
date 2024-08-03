local vim = vim
local vfn = vim.fn

local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
local std_data_path = vfn.stdpath('data')
if type(std_data_path) == 'table' then
    std_data_path = std_data_path[1]
end
local lazypath = vim.fs.joinpath(std_data_path, '/lazy/lazy.nvim')

local function install_lazy_nvim()
    local output = vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        lazyrepo,
        '--branch=stable', -- latest stable release
        lazypath,
    })
    return vim.v.shell_error == 0, output
end

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
    if not vim.uv.fs_stat(lazypath) then
        vim.notify('installing lazy.nvim')
        local ok, err_msg = install_lazy_nvim()
        if not ok then
            vim.notify(string.format('install lazy.nvim failed:\n%s', err_msg), vim.log.levels.ERROR)
            return
        end
    end
    vim.opt.rtp:prepend(lazypath)

    local plugins = get_plugins()
    local opts = {
        concurrency = 8,
        defaults = {
            lazy = true,
        },
        install = {
            missing = true,
            colorscheme = { 'kanagawa' },
        },
        dev = {
            path = '~/workspace/neovim',
            fallback = true,
        },
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
