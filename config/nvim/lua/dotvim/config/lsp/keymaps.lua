local a = require('dotvim.util.async')
local my_lsp = require('dotvim.config.lsp.my')

-- stylua: ignore
local keymaps = {
    -- K   = { 'hover',            desc = 'show documentation',     },
    -- gri = { 'implementation',   desc = 'goto implementation',    },
    -- grr = { 'references',       desc = 'show references',        },
    -- grn = { 'rename',           desc = 'rename',                 },
    -- gds = { 'document_symbol',  desc = 'show document symbols',  },
    -- gra = { 'code_action',      desc = 'code action',            },
    gtd = { 'type_definition',  desc = 'goto type definition',   },
    gk  = { 'signature_help',   desc = 'show signature help',    },
    gd  = { 'definition',       desc = 'goto definition',        },
    gD  = { 'declaration',      desc = 'goto declaration',       },
    gws = { 'workspace_symbol', desc = 'show workspace symbols', },
    goc = { 'outgoing_calls',   desc = 'show outgoing calls',    },
    gic = { 'incoming_calls',   desc = 'show incoming calls',    },
    gcl = { my_lsp.codelens,    desc = 'find and run codelens',  },
}

local M = {}

local function run_action(rhs, ...)
    if type(rhs) == 'function' then
        rhs(...)
    else
        vim.lsp.buf[rhs](...)
    end
end

local function make_callback(rhs)
    return function(...)
        run_action(rhs, ...)
    end
end

---@param client LspClient
---@param bufnr number
function M.on_attach(client, bufnr)
    client = client

    local show_menu = a.wrap(function()
        local choices = vim.tbl_values(keymaps)
        local choice = a.ui
            .select(choices, {
                prompt = 'Lsp actions:',
                format_item = function(item)
                    -- uppercase the first letter
                    local display = item.desc:gsub('^%l', string.upper)
                    return display
                end,
            })
            .await()
        if not choice then
            return
        end
        run_action(choice[1])
    end)

    vim.keymap.set('n', '<leader><space>', show_menu, {
        noremap = false,
        silent = true,
        buffer = bufnr,
        desc = '[Lsp] show menu',
    })

    for key, rhs in pairs(keymaps) do
        local callback = make_callback(rhs[1])
        vim.keymap.set('n', key, callback, {
            noremap = false,
            silent = true,
            buffer = bufnr,
            desc = '[Lsp] ' .. rhs.desc,
        })
    end
end

function M.setup()
    local lsputils = require('dotvim.config.lsp.utils')
    lsputils.on_attach(M.on_attach)
end

return M
