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
        'junegunn/fzf.vim',
        lazy = false,
        dependencies = {
            {
                'junegunn/fzf',
                build = function()
                    vim.fn['fzf#install']()
                end,
            },
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

            vim.api.nvim_command(
                'command! -nargs=? -complete=dir AF '
                    .. 'call fzf#run(fzf#wrap(fzf#vim#with_preview({'
                    .. [['source': 'fd --type f --hidden --follow --exclude .git --no-ignore . '.expand(<q-args>)]]
                    .. '})))'
            )

            local set_keymap = vim.keymap.set
            set_keymap('n', '<leader>ag', ':Ag<CR>', { silent = true, noremap = true, desc = '[FZF] search by ag' })
            set_keymap('n', '<leader>rg', ':Rg<CR>', { silent = true, noremap = true, desc = '[FZF] search by rg' })
            set_keymap('n', '<leader>af', ':AF<CR>', { silent = true, noremap = true, desc = '[FZF] find files' })
            set_keymap('n', '<A-m>', ':Commands<CR>', { silent = true, noremap = true, desc = '[FZF] commands' })
        end,
    },
}
