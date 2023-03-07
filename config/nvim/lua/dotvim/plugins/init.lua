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
    local plugins = {}

    local groups = {
        'dotvim.plugins.base',
        'dotvim.plugins.color',
        'dotvim.plugins.tools',
        'dotvim.plugins.ui',
        'dotvim.plugins.lsp',
        'dotvim.plugins.langs',
    }

    for _, group in ipairs(groups) do
        for _, plug in ipairs(require(group)) do
            table.insert(plugins, plug)
        end
    end

    return plugins
end

function M.setup()
    local plugins = get_plugins()
    local opts = {
        defaults = {
            lazy = true,
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
