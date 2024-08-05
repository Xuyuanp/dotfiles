local vim = vim

local a = require('dotvim.util.async')
local api = a.api

local detect_helm_ft = a.wrap(function(bufnr, path)
    if not bufnr or not path then
        return
    end
    local root = vim.fs.root(bufnr or path, 'Chart.yaml')
    if root then
        vim.api.nvim_set_option_value('filetype', 'helm', { buf = bufnr })
    end
end)

detect_helm_ft(api.nvim_get_current_buf(), vim.fn.expand('%:p'))
