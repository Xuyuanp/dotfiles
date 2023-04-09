local M = {}

function M.setup()
    vim.g.loaded_matchparen = 1
    vim.g.loaded_matchit = 1
    vim.g.loaded_logiPat = 1
    vim.g.loaded_rrhelper = 1
    vim.g.loaded_tarPlugin = 1
    vim.g.loaded_gzip = 1
    vim.g.loaded_zipPlugin = 1
    vim.g.loaded_2html_plugin = 1
    vim.g.loaded_shada_plugin = 1
    vim.g.loaded_spellfile_plugin = 1
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.g.loaded_tutor_mode_plugin = 1
    vim.g.loaded_remote_plugins = 1
    -- vim.g:loaded_man               = 1

    -- redefine leader key
    vim.g.mapleader = ','

    local opt = vim.opt

    opt.shell = '/bin/sh'

    -- Set to auto read when a file is changed from the outside
    opt.autoread = true

    opt.scrolloff = 10

    -- fuck mouse
    opt.mouse = ''

    opt.modifiable = true
    opt.wrap = false
    -- Always show current position
    opt.ruler = true

    -- Show line number
    opt.number = true

    -- if hidden is not set, TextEdit might fail.
    opt.hidden = true

    -- Ignore case when searching
    opt.ignorecase = true
    opt.smartcase = true

    -- Set magic on
    opt.magic = true

    -- No sound on errors.
    opt.errorbells = false
    opt.visualbell = false

    -- show matching bracets
    opt.showmatch = true
    opt.showfulltag = true
    -- How many tenths of a second to blink
    opt.matchtime = 2

    -- Highlight search things
    opt.hlsearch = true
    opt.incsearch = true

    opt.cursorline = true

    -- Display incomplete commands
    opt.showcmd = true

    opt.cmdheight = 1
    opt.laststatus = 3

    -- Turn on wild menu, try typing :h and press <Tab>
    opt.wildmenu = true
    -- Shortens messages to avoid 'press a key' prompt
    opt.shortmess:append({ W = true, I = true, c = true })

    -- Turn backup off
    opt.backup = false
    opt.writebackup = false
    opt.swapfile = false

    -- vim.o.wildignore = '*.o,*.obj,*~,*vim/backups*,*sass-cache*,*DS_Store*,vendor/rails/**,vendor/cache/**,*.gem,log/**,tmp/**,*.png,*.jpg,*.gif'
    opt.wildignore:append({
        '*.o,*.obj,*~',
        '*vim/backups*',
        '*sass-cache*',
        '*DS_Store*',
        'vendor/rails/**',
        'vendor/cache/**',
        '*.gem',
        'log/**',
        'tmp/**',
        '*.png,*.jpg,*.gif',
    })

    -- Display tabs and trailing spaces visually
    opt.list = true
    opt.listchars:append({
        tab = '  ',
        trail = '·',
        extends = '',
        precedes = '',
    })

    -- always show signcolumn
    opt.signcolumn = 'yes'

    -- Text options
    opt.expandtab = true
    opt.shiftwidth = 4
    opt.tabstop = 4
    opt.smarttab = true

    opt.linebreak = true
    opt.textwidth = 800

    opt.smartindent = true
    opt.autoindent = true

    vim.g.vimsyn_embed = 'lPr'

    opt.pumblend = 20
    opt.winblend = 20

    opt.fillchars:append({
        eob = ' ',
        vert = '┃',
    })

    -- don't syntax-highlight long lines
    opt.synmaxcol = 200

    -- Set completeopt to have a better completion experience
    opt.completeopt = 'menuone,noinsert,noselect'

    opt.termguicolors = true

    local sign_define = vim.fn.sign_define
    sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
    sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
    sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
    sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

    if vim.env.SSH_TTY then
        local osc52 = require('dotvim.util.osc52')
        vim.g.clipboard = {
            name = 'osc52',
            copy = { ['+'] = osc52.copy, ['*'] = osc52.copy },
            paste = { ['+'] = osc52.paste, ['*'] = osc52.paste },
        }
    end

    if vim.g.neovide then
        opt.guifont = 'FiraCode Nerd Font Mono:h13'

        vim.g.neovide_fullscreen = true
        vim.g.neovide_transparency = 0.9
        vim.g.neovide_no_idle = true
        vim.g.neovide_cursor_antialiasing = true
    end

    -- TODO: move to somewhere
    vim.api.nvim_create_user_command('Nerdfonts', function()
        require('dotvim.util.nerdfonts').pick()
    end, {})
end

return M
