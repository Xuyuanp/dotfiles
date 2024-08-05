local M = {}

local xdg_data_path = vim.fn.stdpath('data')
if type(xdg_data_path) == 'table' then
    xdg_data_path = xdg_data_path[1]
end
local extension_path = vim.fs.joinpath(xdg_data_path, '/mason/packages/codelldb/extension')
local codelldb_path = vim.fs.joinpath(extension_path, '/adapter/codelldb')
local liblldb_path = vim.fs.joinpath(extension_path, '/lldb/lib/liblldb.so')

function M.setup()
    local default_config = require('dotvim.config.lsp.utils')
    vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {},
        -- LSP configuration
        server = {
            on_attach = default_config.on_attach,
            handlers = default_config.handlers,
            capabilities = default_config.capabilities,
            default_settings = {
                -- rust-analyzer language server configuration
                ['rust-analyzer'] = {
                    diagnostics = {
                        enable = true,
                        disabled = { 'unresolved-proc-macro' },
                    },
                },
            },
        },
        -- DAP configuration
        dap = {
            adapter = require('rustaceanvim.config').get_codelldb_adapter(codelldb_path, liblldb_path),
        },
    }

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'rust',
        callback = function()
            vim.keymap.set('n', '<leader>R', function()
                vim.cmd.RustLsp('runnables')
            end, { silent = true, remap = true, desc = '[rust] show runnables' })
        end,
    })
end

return M
