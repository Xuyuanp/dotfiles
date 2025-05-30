local features = require('dotvim.features')

local M = {}

M.icons = {
    diagnostic = {
        error = '',
        warn = '',
        info = '',
        hint = '',
    },
    git = {
        add = '',
        delete = '',
        change = '',

        branch = '',
        tag = '',
        commit = '',
    },
}

function M.setup()
    -- redefine leader key
    vim.g.mapleader = ','

    local opt = vim.opt

    -- Set to auto read when a file is changed from the outside
    opt.autoread = true

    opt.scrolloff = 10

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

    opt.fillchars:append({
        eob = ' ',
        horiz = '━',
        horizup = '┻',
        horizdown = '┳',
        vert = '┃',
        vertleft = '┫',
        vertright = '┣',
        verthoriz = '╋',
    })

    -- don't syntax-highlight long lines
    opt.synmaxcol = 200

    -- Set completeopt to have a better completion experience
    opt.completeopt = 'menuone,noinsert,noselect'

    opt.termguicolors = true

    opt.conceallevel = 1

    opt.winblend = features.transparent and 0 or 20

    opt.winborder = 'rounded'

    vim.opt.fillchars:append({
        fold = ' ',
        foldopen = '',
        foldsep = ' ',
        foldclose = '',
    })
    vim.o.foldcolumn = '0' -- disabled foldcolumn to avoid display the number of fold level
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldmethod = 'expr'
    vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.o.foldenable = true

    vim.filetype.add({
        filename = {
            ['.envrc'] = 'sh',
        },
        extension = {
            ['tpl'] = 'helm',
        },
        pattern = {
            ['.*/templates/.*%.yaml'] = 'helm',
            ['.*/zed/.+%.json'] = 'jsonc',
        },
    })

    vim.diagnostic.config({
        severity_sort = true,
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = M.icons.diagnostic.error,
                [vim.diagnostic.severity.WARN] = M.icons.diagnostic.warn,
                [vim.diagnostic.severity.INFO] = M.icons.diagnostic.info,
                [vim.diagnostic.severity.HINT] = M.icons.diagnostic.hint,
            },
        },
        virtual_text = true,
    })

    if vim.fn.executable('ghostty') then
        if vim.fn.has('mac') then
            opt.rtp:append('/Applications/Ghostty.app/Contents/Resources/nvim/site')
        end
    end
end

return M
