local M = {}

local function has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local function toCamelCase(str)
    return str:gsub('(%a)(%w*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

local function copilot_cmp()
    local ok, comparators = pcall(require, 'copilot_cmp.comparators')
    if ok then
        return comparators.prioritize
    end
    return function() end
end

---@param entry cmp.Entry
---@return string[]
function M.entry_get_documentation(entry)
    local item = entry.completion_item
    if entry.source.name ~= 'copilot' and entry.context.filetype == 'lua' then
        item.detail = nil
    end

    local docs = {}
    if item.detail then
        local ft = entry.context.filetype
        local detail = vim.trim(item.detail)
        local marked = ('```%s\n%s```'):format(ft, detail)
        docs = vim.split(marked, '\n')
    end

    if item.documentation then
        if #docs > 0 then
            table.insert(docs, '---')
        end
        docs = vim.lsp.util.convert_input_to_markdown_lines(item.documentation, docs)
    end
    return docs
end

local function override_entry_get_documentation()
    local entry = require('cmp.entry')
    local backup = entry.get_documentation
    entry.get_documentation = function(self)
        return M.entry_get_documentation(self)
    end
    return backup
end

function M.stylize_markdown(bufnr, contents, opts)
    contents = vim.lsp.util._normalize_markdown(contents, {
        width = vim.lsp.util._make_floating_popup_size(contents, opts),
    })

    pcall(vim.treesitter.start, bufnr, 'markdown')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)

    return contents
end

local function override_stylize_markdown()
    local backup = vim.lsp.util.stylize_markdown

    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.util.stylize_markdown = M.stylize_markdown

    return backup
end

function M.setup()
    local cmp = require('cmp')
    local compare = require('cmp.config.compare')

    override_stylize_markdown()
    override_entry_get_documentation()

    local compare_kind = function(entry1, entry2)
        local kind1 = entry1:get_kind()
        kind1 = kind1 == cmp.lsp.CompletionItemKind.Text and 100 or kind1
        local kind2 = entry2:get_kind()
        kind2 = kind2 == cmp.lsp.CompletionItemKind.Text and 100 or kind2
        if kind1 ~= kind2 then
            local diff = kind1 - kind2
            if diff < 0 then
                return true
            elseif diff > 0 then
                return false
            end
        end
    end

    local lspkind = require('lspkind')

    cmp.setup({
        completion = {
            completeopt = 'menu,menuone,noinsert',
        },

        snippet = {
            expand = function(args)
                vim.snippet.expand(args.body)
            end,
        },

        mapping = {
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-b>'] = cmp.mapping.scroll_docs(-5),
            ['<C-f>'] = cmp.mapping.scroll_docs(5),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                else
                    fallback()
                end
            end),
            ['<C-e>'] = cmp.mapping.close(),
            ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() and has_words_before() then
                    cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                else
                    fallback()
                end
            end, { 'i', 's' }),
        },
        window = {
            documentation = {
                border = 'rounded',
                winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
                zindex = 1001,
            },
        },
        formatting = {
            fields = { 'abbr', 'kind', 'menu' },
            expandable_indicator = true,
            format = lspkind.cmp_format({
                mode = 'symbol_text',
                maxwidth = 50,
                menu = setmetatable({
                    copilot = '[Github]',
                    nvim_lsp = '[LSP]',
                }, {
                    __index = function(obj, key)
                        local v = '[' .. toCamelCase(key) .. ']'
                        rawset(obj, key, v)
                        return v
                    end,
                }),
            }),
        },
        preselect = cmp.PreselectMode.None,
        sources = cmp.config.sources({
            { name = 'codeium' },
            { name = 'copilot' },
            { name = 'nvim_lsp' },
            { name = 'nvim_lsp_signature_help' },
            { name = 'snippets' },
            { name = 'lazydev' },
        }, {
            {
                name = 'buffer',
                keyword_length = 5,
                option = {
                    -- Buffer completions from all visible buffers (that aren't huge).
                    get_bufnrs = function()
                        local bufs = {}

                        for _, win in ipairs(vim.api.nvim_list_wins()) do
                            local buf = vim.api.nvim_win_get_buf(win)
                            if vim.bo[buf].filetype ~= 'bigfile' then
                                table.insert(bufs, buf)
                            end
                        end

                        return bufs
                    end,
                },
            },
            { name = 'path' },
            { name = 'tmux', keyword_length = 5 },
            { name = 'calc' },
        }),
        sorting = {
            priority_weight = 2,
            comparators = {
                copilot_cmp(),
                compare.offset,
                compare.exact,
                compare.score,
                compare.recently_used,
                compare_kind,
                compare.sort_text,
                compare.length,
                compare.order,
            },
        },
        experimental = {
            ghost_text = {
                hl_group = 'LspCodeLens',
            },
        },
    })

    local ok, autopair_cmp = pcall(require, 'nvim-autopairs.completion.cmp')
    if ok then
        cmp.event:on('confirm_done', autopair_cmp.on_confirm_done({ map_char = { tex = '' } }))
    end
end

return M
