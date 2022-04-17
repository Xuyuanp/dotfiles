local vfn = vim.fn
local command = vim.api.nvim_command

local ok, impatient = pcall(require, 'impatient')
if ok then
    impatient.enable_profile()
end

if vfn.has('osx') then
    vfn.setenv('MACOSX_DEPLOYMENT_TARGET', '10.8')
end

local std_data_path = vfn.stdpath('data')

local install_path = std_data_path .. '/site/pack/packer/opt/packer.nvim'
local compile_path = std_data_path .. '/site/plugin/packer_compiled.vim'
local packer_repo = 'https://github.com/wbthomason/packer.nvim'

local bootstrap = false

command('silent! packadd packer.nvim')
local ok, packer = pcall(require, 'packer')

if not ok then
    print('Installing packer...')
    vfn.delete(install_path, 'rf')
    local output = vfn.system({
        'git',
        'clone',
        packer_repo,
        install_path,
    })
    if vim.v.shell_error ~= 0 then
        error(output)
    end

    command('packadd packer.nvim')
    ok, packer = pcall(require, 'packer')

    if ok then
        print('Installed packer.nvim successfully.')
    else
        error('Installed packer.nvim failed:!')
    end

    bootstrap = true
end

local M = {}

local function startup_fn(use)
    use('lewis6991/impatient.nvim')

    use({ 'wbthomason/packer.nvim', opt = true })

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
            use(plug)
        end
    end

    if bootstrap then
        packer.sync()
    end

    if vfn.empty(vfn.glob(compile_path)) > 0 then
        packer.compile()
    end
end

function M.setup()
    packer.startup({
        startup_fn,

        config = {
            compile_path = compile_path,
            compile_on_sync = true,
            auto_clean = true,
            max_jobs = 8,
            display = {
                open_fn = function()
                    return require('packer.util').float({ border = 'rounded' })
                end,
                prompt_border = 'rounded',
            },
        },
    })
end

return M
