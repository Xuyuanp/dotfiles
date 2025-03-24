local features = require('dotvim.features')

local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
local std_data_path = vim.fn.stdpath('data')
if type(std_data_path) == 'table' then
    std_data_path = std_data_path[1]
end
local lazypath = vim.fs.joinpath(std_data_path, 'lazy/lazy.nvim')

---@return boolean, string?
local function install_lazy_nvim()
    local completed = vim.system({
        'git',
        'clone',
        '--filter=blob:none',
        lazyrepo,
        '--branch=stable', -- latest stable release
        lazypath,
    }):wait()
    return completed.code == 0, completed.stderr or completed.stdout
end

local M = {}

local function get_plugins()
    return {
        { 'folke/lazy.nvim', version = '*' },
        features.mini and { import = 'dotvim.mini' } or { import = 'dotvim.plugins' },
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
        ui = {
            border = 'rounded',
        },
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
                reset = false,
                disabled_plugins = {
                    'gzip',
                    'netrwPlugin',
                    'tarPlugin',
                    'tutor',
                    'zipPlugin',
                    'spellfile',
                    'rplugin',
                },
            },
        },
    }
    require('lazy').setup(plugins, opts)

    vim.api.nvim_create_autocmd('User', {
        group = vim.api.nvim_create_augroup('dotvim.lazy', { clear = true }),
        pattern = 'VeryLazy',
        callback = function(args)
            vim.defer_fn(function()
                vim.api.nvim_exec_autocmds('User', {
                    pattern = 'SuperLazy',
                    data = args.data,
                })
            end, 50)
        end,
    })
end

return M
