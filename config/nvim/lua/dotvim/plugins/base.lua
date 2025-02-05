return {
    {
        'nvim-lua/plenary.nvim',
    },

    {
        'nvim-lua/popup.nvim',
    },

    {
        'MunifTanjim/nui.nvim',
    },

    {
        'ibhagwan/fzf-lua',
        cmd = 'FzfLua',
        opts = {},
    },

    {
        'junegunn/fzf.vim',
        dependencies = {
            { 'junegunn/fzf', build = './install --bin' },
        },
        cmd = { 'FZF', 'AF' },
        keys = {
            { '<leader>rg', ':Rg<CR>', desc = '[FZF] search by rg' },
        },
        config = function()
            vim.g.fzf_layout = {
                window = {
                    width = 0.9,
                    height = 0.9,
                    border = 'rounded',
                },
            }
            vim.g.fzf_action = {
                ['ctrl-x'] = 'split',
                ['ctrl-v'] = 'vsplit',
            }

            vim.api.nvim_create_user_command('AF', function(ctx)
                local fzf_run = vim.fn['fzf#run']
                local fzf_wrap = vim.fn['fzf#wrap']
                local fzf_vim_with_preview = vim.fn['fzf#vim#with_preview']
                fzf_run(fzf_wrap(fzf_vim_with_preview({
                    source = 'fd --type f --hidden --follow --exclude .git --no-ignore . ' .. ctx.args,
                })))
            end, {
                nargs = '?',
                complete = 'dir',
            })
        end,
    },
}
