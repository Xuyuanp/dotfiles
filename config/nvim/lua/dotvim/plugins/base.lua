return {
    {
        'nvim-lua/plenary.nvim',
        name = 'plenary',
        lazy = true,
    },

    {
        'nvim-lua/popup.nvim',
        name = 'popup',
        lazy = true,
    },

    {
        'junegunn/fzf.vim',
        name = 'fzfvim',
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
            set_keymap('n', '<leader>ag', ':Ag<CR>', { silent = true, noremap = true })
            set_keymap('n', '<leader>rg', ':Rg<CR>', { silent = true, noremap = true })
            set_keymap('n', '<leader>af', ':AF<CR>', { silent = true, noremap = true })
            set_keymap('n', '<A-m>', ':Commands<CR>', { silent = true, noremap = true })
        end,
    },
}
