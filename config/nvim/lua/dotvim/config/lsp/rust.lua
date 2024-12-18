local M = {}

local xdg_data_path = vim.fn.stdpath('data')
if type(xdg_data_path) == 'table' then
    xdg_data_path = xdg_data_path[1]
end
local extension_path = vim.fs.joinpath(xdg_data_path, '/mason/packages/codelldb/extension')
local codelldb_path = vim.fs.joinpath(extension_path, '/adapter/codelldb')
local this_os = vim.uv.os_uname().sysname
-- The liblldb extension is .so for Linux and .dylib for MacOS
local liblldb_path = vim.fs.joinpath(extension_path, 'lldb/lib/liblldb.' .. (this_os == 'Linux' and 'so' or 'dylib'))

-- The path is different on Windows
if this_os:find('Windows') then
    codelldb_path = vim.fs.joinpath(extension_path, 'adapter\\codelldb.exe')
    liblldb_path = vim.fs.joinpath(extension_path, 'lldb\\bin\\liblldb.dll')
end

function M.setup()
    vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {},
        -- LSP configuration
        server = {
            default_settings = {
                -- rust-analyzer language server configuration
                ['rust-analyzer'] = {
                    diagnostics = {
                        enable = true,
                        disabled = { 'unresolved-proc-macro' },
                    },
                    -- rust-analyzer.semanticHighlighting.strings.enable
                    semanticHighlighting = {
                        strings = {
                            enable = false,
                        },
                    },
                },
            },
        },
        -- DAP configuration
        dap = {
            adapter = require('rustaceanvim.config').get_codelldb_adapter(codelldb_path, liblldb_path),
        },
    }

    local ok, neotest = pcall(require, 'neotest')
    if ok then
        local adapter = require('rustaceanvim.neotest')
        ---@diagnostic disable-next-line: missing-fields
        neotest.setup({
            adapters = {
                adapter,
            },
        })
    end

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
