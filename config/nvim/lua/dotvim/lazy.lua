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
        {
            'Xuyuanp/neochat.nvim',
            dev = vim.fn.exists('~/workspace/neovim/neochat.nvim'),
            build = function()
                vim.fn.system({
                    'pip',
                    'install',
                    '-U',
                    'openai',
                })
            end,
            keys = {
                {
                    '<A-g>',
                    require('dotvim.util').lazy_require('neochat').toggle,
                    mode = { 'n', 'i' },
                    desc = 'toggle neochat',
                    noremap = false,
                },
            },
            dependencies = {
                'MunifTanjim/nui.nvim',
            },
            config = function()
                require('neochat').setup({})
            end,
        },
    }
end

function M.setup()
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
