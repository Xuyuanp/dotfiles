vim.cmd([[let &rtp.=','.getcwd()]])

if #vim.api.nvim_list_uis() == 0 then
    local mini_test = vim.fn.expand('~/.local/share/nvim/lazy/mini.test')
    vim.cmd('set rtp+=' .. mini_test)

    require('mini.test').setup()
end
