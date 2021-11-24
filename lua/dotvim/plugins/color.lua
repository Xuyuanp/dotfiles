return {
    {
        'sainnhe/gruvbox-material',
        setup = function()
            local vim = vim
            local execute = vim.api.nvim_command

            execute([[ let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum" ]])
            execute([[ let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum" ]])
            execute([[ let &t_ZH = "\e[3m" ]])
            execute([[ let &t_ZR = "\e[23m" ]])
            vim.opt.termguicolors = true

            vim.g.gruvbox_material_enable_italic = 1
            vim.g.gruvbox_material_disable_italic_comment = 1
            vim.g.gruvbox_material_enable_bold = 1
            vim.g.gruvbox_material_better_performance = 1
            vim.g.gruvbox_material_palette = 'original'
            vim.g.gruvbox_material_background = 'hard'
        end,
        config = function()
            local vim = vim
            local execute = vim.api.nvim_command

            local dotcolors = require('dotvim.colors')
            dotcolors.enable_auto_update()

            vim.opt.background = 'dark'
            execute([[ colorscheme gruvbox-material ]])

            dotcolors.add_highlight('EndOfBuffer', {
                fg = dotcolors.colors.Sign.bg,
            })
            dotcolors.add_highlight('VertSplit', {
                fg = dotcolors.colors.black_pure,
            })
        end,
    },

    {
        'glepnir/zephyr-nvim',
        disable = true,
        config = function()
            local vim = vim
            local execute = vim.api.nvim_command

            vim.opt.background = 'dark'
            execute([[ colorscheme zephyr ]])
        end,
    },
}