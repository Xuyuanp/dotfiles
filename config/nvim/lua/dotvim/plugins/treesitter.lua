return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        lazy = false,
        opts = {
            ensure_installed = {
                'lua',
                'vim',
                'vimdoc',
                'markdown',
                'markdown_inline',
                'diff',
                'query',
                'go',
                'rust',
                'python',
            },
            ignore_install = {},
            sync_install = false,
            auto_install = false,
            modules = {},
            highlight = {
                enable = true, -- false will disable the whole extension
            },
            incremental_selection = {
                enable = true,
            },
            indent = {
                enable = true,
                disable = { 'python', 'yaml', 'helm' },
            },
        },
        config = function(_, opts)
            require('dotvim.config.treesitter').setup(opts)
        end,
    },

    {

        'nvim-treesitter/nvim-treesitter-textobjects',
        lazy = false,
        dependencies = {
            {
                'nvim-treesitter/nvim-treesitter',
                opts = {
                    textobjects = {
                        select = {
                            enable = true,

                            -- Automatically jump forward to textobj, similar to targets.vim
                            lookahead = true,

                            keymaps = {
                                -- You can use the capture groups defined in textobjects.scm
                                ['af'] = '@function.outer',
                                ['if'] = '@function.inner',
                                ['ac'] = '@class.outer',
                                -- You can optionally set descriptions to the mappings (used in the desc parameter of
                                -- nvim_buf_set_keymap) which plugins like which-key display
                                ['ic'] = { query = '@class.inner', desc = 'Select inner part of a class region' },
                                -- You can also use captures from other query groups like `locals.scm`
                                ['as'] = { query = '@scope', query_group = 'locals', desc = 'Select language scope' },
                            },
                            -- You can choose the select mode (default is charwise 'v')
                            --
                            -- Can also be a function which gets passed a table with the keys
                            -- * query_string: eg '@function.inner'
                            -- * method: eg 'v' or 'o'
                            -- and should return the mode ('v', 'V', or '<c-v>') or a table
                            -- mapping query_strings to modes.
                            selection_modes = {
                                ['@parameter.outer'] = 'v', -- charwise
                                ['@function.outer'] = 'V', -- linewise
                                ['@class.outer'] = '<c-v>', -- blockwise
                            },
                            -- If you set this to `true` (default is `false`) then any textobject is
                            -- extended to include preceding or succeeding whitespace. Succeeding
                            -- whitespace has priority in order to act similarly to eg the built-in
                            -- `ap`.
                            --
                            -- Can also be a function which gets passed a table with the keys
                            -- * query_string: eg '@function.inner'
                            -- * selection_mode: eg 'v'
                            -- and should return true of false
                            include_surrounding_whitespace = false,
                        },
                    },
                },
            },
        },
    },
    {

        'RRethy/nvim-treesitter-textsubjects',
        lazy = false,
        dependencies = {
            {
                'nvim-treesitter/nvim-treesitter',
                opts = {
                    textsubjects = {
                        enable = true,
                        prev_selection = ',', -- (Optional) keymap to select the previous selection
                        keymaps = {
                            ['.'] = 'textsubjects-smart',
                            [';'] = 'textsubjects-container-outer',
                            ['i;'] = { 'textsubjects-container-inner', desc = 'Select inside containers (classes, functions, etc.)' },
                        },
                    },
                },
            },
        },
    },

    {
        'JoosepAlviste/nvim-ts-context-commentstring',
        lazy = false,
        init = function()
            vim.g.skip_ts_context_commentstring_module = true
        end,
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {},
    },
}
