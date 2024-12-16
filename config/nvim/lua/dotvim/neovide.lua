local features = require('dotvim.features')

local M = {}

function M.setup()
    vim.g.neovide_transparency = features.transparent and 0.8 or 1
    vim.g.neovide_no_idle = true
    vim.g.neovide_cursor_antialiasing = true
    vim.g.neovide_input_macos_option_key_is_meta = 'both'
end

return M
