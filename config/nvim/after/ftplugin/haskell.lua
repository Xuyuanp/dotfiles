vim.bo.iskeyword = 'a-z,A-Z,_,.,39,<,>,*,$,#'
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true
vim.bo.autoindent = true

vim.opt_local.formatoptions:append('tcro')
vim.opt_local.formatoptions:remove('l')
