local M = {}

function M.setup()
    local ts_configs = require('nvim-treesitter.configs')

    ts_configs.setup({
        highlight = {
            enable = true, -- false will disable the whole extension
        },
        incremental_selection = {
            enable = true,
        },
        refactor = {
            highlight_definitions = { enable = true },
            highlight_current_scope = {
                enable = true,
            },
            navigation = { enable = false },
            smart_rename = { enable = false },
        },
        textobjects = { enable = true },
        playground = {
            enable = true,
            disable = {},
            updatetime = 25,
            persist_queries = false,
        },
        rainbow = {
            enable = true,
            extend_mode = true,
            max_file_lines = 2000,
        },
    })

    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.o.foldlevel = 100
end

return M
