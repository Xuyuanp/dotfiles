local M = {}

local xdg_data_path = vim.fn.stdpath('data')
local extension_path = vim.fs.joinpath(xdg_data_path, '/mason/packages/codelldb/extension')
local codelldb_path = vim.fs.joinpath(extension_path, '/adapter/codelldb')
local liblldb_path = vim.fs.joinpath(extension_path, '/lldb/lib/liblldb.so')

function M.setup(server)
    local opts = {
        tools = { -- rust-tools options
            -- Whether to show hover actions inside the hover window
            -- This overrides the default hover handler
            -- hover_with_actions = true,

            executor = require('rust-tools.executors').termopen,

            reload_workspace_from_cargo_toml = true,

            -- These apply to the default RustSetInlayHints command
            inlay_hints = {
                auto = false,
            },

            hover_actions = {
                -- the border that is used for the hover window
                -- see vim.api.nvim_open_win()
                border = {
                    { '╭', 'FloatBorder' },
                    { '─', 'FloatBorder' },
                    { '╮', 'FloatBorder' },
                    { '│', 'FloatBorder' },
                    { '╯', 'FloatBorder' },
                    { '─', 'FloatBorder' },
                    { '╰', 'FloatBorder' },
                    { '│', 'FloatBorder' },
                },

                -- whether the hover action window gets automatically focused
                auto_focus = true,
            },

            -- settings for showing the crate graph based on graphviz and the dot
            -- command
            crate_graph = {
                -- Backend used for displaying the graph
                -- see: https://graphviz.org/docs/outputs/
                -- default: x11
                backend = 'x11',
                -- where to store the output, nil for no output stored (relative
                -- path from pwd)
                -- default: nil
                output = nil,
                -- true for all crates.io and external crates, false only the local
                -- crates
                -- default: true
                full = true,
            },
        },
        server = server,
        -- debugging stuff
        dap = {
            adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path),
        },
    }
    local rt = require('rust-tools')
    rt.setup(opts)

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        callback = function()
            vim.keymap.set('n', '<leader>R', function()
                rt.runnables.runnables()
            end, { silent = true, remap = true, desc = '[rust] show runnables' })
        end,
    })
end

return M
