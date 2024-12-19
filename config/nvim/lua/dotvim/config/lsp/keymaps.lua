local a = require('dotvim.util.async')
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

local M = {}

---@param client LspClient
---@param bufnr number
function M.on_attach(client, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        K   = { 'hover',            desc = 'show documentation',     method = nil                                    },
        gi  = { 'implementation',   desc = 'goto implementation',    method = LspMethods.textDocument_implementation },
        gk  = { 'signature_help',   desc = 'show signature help',    method = LspMethods.textDocument_signatureHelp  },
        gd  = { 'definition',       desc = 'goto definition',        method = LspMethods.textDocument_definition     },
        gtd = { 'type_definition',  desc = 'goto type definition',   method = LspMethods.textDocument_typeDefinition },
        grr = { 'references',       desc = 'show references',        method = LspMethods.textDocument_references     },
        grn = { 'rename',           desc = 'rename',                 method = LspMethods.textDocument_rename         },
        gds = { 'document_symbol',  desc = 'show document symbols',  method = LspMethods.textDocument_documentSymbol },
        gws = { 'workspace_symbol', desc = 'show workspace symbols', method = LspMethods.workspace_symbol            },
        gca = { 'code_action',      desc = 'code action',            method = LspMethods.textDocument_codeAction     },
        goc = { 'outgoing_calls',   desc = 'show outgoing calls',    method = LspMethods.callHierarchy_outgoingCalls },
        gic = { 'incoming_calls',   desc = 'show incoming calls',    method = LspMethods.callHierarchy_incomingCalls },
        gcl = { my_lsp.codelens,    desc = 'find and run codelens',  method = nil                                    },
    }
    local function make_action(rhs)
        return function(...)
            if type(rhs) == 'function' then
                rhs(...)
            else
                vim.lsp.buf[rhs](...)
            end
        end
    end

    for key, rhs in pairs(keymaps) do
        if not rhs.method or client:supports_method(rhs.method) then
            set_keymap('n', key, make_action(rhs[1]), {
                noremap = false,
                silent = true,
                buffer = bufnr,
                desc = '[Lsp] ' .. rhs.desc,
            })
        end
    end

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
        make_action(choice[1])()
    end)

    set_keymap('n', '<space><space>', show_menu, {
        noremap = false,
        silent = true,
        buffer = bufnr,
        desc = '[Lsp] show menu',
    })
end

function M.setup()
    local lsputils = require('dotvim.config.lsp.utils')
    lsputils.on_attach(M.on_attach)
end

return M
