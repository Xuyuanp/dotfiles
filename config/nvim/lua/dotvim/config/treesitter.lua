local M = {}

local custom_directives = {
    ['absoffset!'] = function(match, _, _, pred, metadata)
        ---@cast pred integer[]
        local capture_id = pred[2]
        if not metadata[capture_id] then
            metadata[capture_id] = {}
        end

        local range = metadata[capture_id].range or { match[capture_id]:range() }
        local start_row_offset = pred[3] or 0
        local start_col_offset = pred[4] or 0
        local end_row_offset = pred[5] or 0
        local end_col_offset = pred[6] or 0

        range[1] = range[1] + start_row_offset
        range[2] = range[2] + start_col_offset -- offset from start of row
        range[3] = range[1] + end_row_offset
        range[4] = range[2] + end_col_offset -- offset from start of col

        -- If this produces an invalid range, we just skip it.
        if range[1] < range[3] or (range[1] == range[3] and range[2] <= range[4]) then
            metadata[capture_id].range = range
        end
    end,
}

function M.register_custom_directives()
    for name, handler in pairs(custom_directives) do
        vim.treesitter.query.add_directive(name, handler, true)
    end
end

function M.setup()
    M.register_custom_directives()

    local ts_configs = require('nvim-treesitter.configs')

    ts_configs.setup({
        highlight = {
            enable = true, -- false will disable the whole extension
        },
        incremental_selection = {
            enable = true,
        },
        indent = {
            enable = true,
            disable = { 'python' },
        },
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
        textsubjects = {
            enable = true,
            prev_selection = ',', -- (Optional) keymap to select the previous selection
            keymaps = {
                ['i<cr>'] = 'textsubjects-smart',
                ['ii'] = 'textsubjects-container-inner',
                ['io'] = 'textsubjects-container-outer',
            },
        },
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
        context_commentstring = {
            enable = true,
        },
    })

    require('treesitter-context').setup({
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20, -- The Z-index of the context window
    })

    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
    vim.o.foldlevel = 100
end

return M
