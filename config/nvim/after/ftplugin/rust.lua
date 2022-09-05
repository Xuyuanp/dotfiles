local tools = vim.F.npcall(require, 'rust-tools')

if tools then
    vim.keymap.set('n', '<leader>R', function()
        tools.runnables.runnables()
    end, { silent = true, buffer = true })
end
