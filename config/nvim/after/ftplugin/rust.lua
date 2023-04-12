local vim = vim

local query = vim.treesitter.query.parse(
    'rust',
    [[
(
 (macro_invocation
   (scoped_identifier
     path: (identifier) @_path
     name: (identifier) @_identifier)

   (token_tree (raw_string_literal) @raw))

 (#eq? @_path "sqlx")
 (#match? @_identifier "^query")
 )
]]
)

local format_dat_sql = function(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if vim.bo[bufnr].filetype ~= 'rust' then
        vim.notify('can only be used in rust')
        return
    end

    local parser = vim.treesitter.get_parser(bufnr, 'rust', {})
    local tree = parser:parse()[1]

    local bin = vim.api.nvim_get_runtime_file('scripts/sqlformat.py', false)[1]

    local changes = {}
    for id, node, _ in query:iter_captures(tree:root(), bufnr, 0, -1) do
        if id == 3 then
            local text = vim.treesitter.get_node_text(node, bufnr)
            -- trim prefix `r#"` and suffix `"#`
            text = string.sub(text, 4, #text - 2)

            local formatted = vim.fn.systemlist({ 'python', bin }, text)
            if vim.v.shell_error ~= 0 then
                vim.notify(string.format('format SQL failed:\n%s', formatted), vim.log.levels.WARN)
                return
            end

            local range = { node:range() }
            local rep = string.rep(' ', range[2])
            for idx, line in ipairs(formatted) do
                formatted[idx] = rep .. line
            end
            table.insert(formatted, 1, 'r#"')
            table.insert(formatted, rep .. '"#')
            table.insert(changes, 1, {
                start_row = range[1],
                start_col = range[2],
                end_row = range[3],
                end_col = range[4],
                formatted = formatted,
            })
        end
    end

    for _, change in ipairs(changes) do
        vim.api.nvim_buf_set_text(bufnr, change.start_row, change.start_col, change.end_row, change.end_col, change.formatted)
    end
end

vim.api.nvim_create_user_command('SqlMagic', function()
    format_dat_sql()
end, {})

local group = vim.api.nvim_create_augroup('rust-sql-magic', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    buffer = 0,
    desc = '[rust] auto format sql in sqlx::query',
    callback = function()
        format_dat_sql()
    end,
})
