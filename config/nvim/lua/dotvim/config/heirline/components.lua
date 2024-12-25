local conditions = require('heirline.conditions')
local utils = require('heirline.utils')
local mini_icons = require('mini.icons')

local icons = require('dotvim.settings').icons

local M = {}

M.Space = { provider = ' ' }

M.Align = { provider = '%=' }

M.VimMode = {
    static = {
        mode_names = {
            n = '',
            v = 'V',
            V = 'V-L',
            ['\22'] = 'V-B',
            s = 'S',
            S = 'S_',
            ['\19'] = '^S',
            i = 'I',
            R = 'R',
            c = 'C',
            r = '...',
            ['!'] = '!',
            t = '',
        },
        mode_colors = {
            n = 'purple',
            i = 'green',
            v = 'blue',
            V = 'blue',
            ['\22'] = 'blue',
            c = 'red',
            s = 'cyan',
            S = 'cyan',
            ['\19'] = 'cyan',
            R = 'orange',
            r = 'orange',
            ['!'] = 'red',
            t = 'red',
        },
    },
    init = function(self)
        self.mode = vim.fn.mode()
    end,
    provider = function(self)
        return '▊ ' .. self.mode_names[self.mode]
    end,
    hl = function(self)
        local mode = self.mode:sub(1, 1) -- get only the first mode character
        return { fg = self.mode_colors[mode], bold = true }
    end,
    update = {
        'ModeChanged',
        pattern = '*:*',
        callback = vim.schedule_wrap(function()
            vim.cmd('redrawstatus')
        end),
    },
}

local FileNameBlock = {
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
    end,
}

M.FileIcon = {
    init = function(self)
        local filename = self.filename
        self.icon, self.icon_color = mini_icons.get('file', filename)
    end,
    provider = function(self)
        return self.icon and (self.icon .. ' ')
    end,
    hl = function(self)
        return self.icon_color
    end,
}

M.WorkDir = {
    init = function(self)
        self.icon = ' '
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ':~')
    end,
    hl = { fg = utils.get_highlight('Directory').fg, bold = true },

    flexible = 2,

    {
        provider = function(self)
            local trail = self.cwd:sub(-1) == '/' and '' or '/'
            return self.icon .. self.cwd .. trail .. ' '
        end,
    },
    {
        provider = function(self)
            local cwd = vim.fn.pathshorten(self.cwd)
            local trail = self.cwd:sub(-1) == '/' and '' or '/'
            return self.icon .. cwd .. trail .. ' '
        end,
    },
    {
        provider = '',
    },
}

M.FileName = {
    init = function(self)
        local filename = self.filename or vim.api.nvim_buf_get_name(0)
        self.lfilename = vim.fn.fnamemodify(filename, ':.')
        if self.lfilename == '' then
            self.lfilename = '[No Name]'
        end
    end,
    hl = { bold = true },

    flexible = 3,

    {
        provider = function(self)
            return self.lfilename
        end,
    },
    {
        provider = function(self)
            return vim.fn.pathshorten(self.lfilename)
        end,
    },
}

M.FileFlags = {
    {
        condition = function()
            return vim.bo.modified
        end,
        provider = ' ',
        hl = { fg = 'tan' },
    },
    {
        condition = function()
            return not vim.bo.modifiable or vim.bo.readonly
        end,
        provider = ' ',
        hl = { fg = 'orange' },
    },
}

M.FileSize = {
    provider = function()
        -- stackoverflow, compute human readable file size
        local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
        local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
        fsize = (fsize < 0 and 0) or fsize
        if fsize < 1024 then
            return fsize .. suffix[1]
        end
        local i = math.floor((math.log(fsize) / math.log(1024)))
        return string.format('%.2g%s', fsize / math.pow(1024, i), suffix[i + 1])
    end,
}

M.FileNameBlock = utils.insert(
    FileNameBlock,
    M.WorkDir,
    M.FileIcon,
    M.FileName,
    -- M.FileSize,
    M.FileFlags,
    { provider = '%<' } -- this means that the statusline is cut here when there's not enough space
)

M.FileType = {
    provider = function()
        return string.upper(vim.bo.filetype)
    end,
    hl = function()
        local _, hl = mini_icons.get('filetype', vim.bo.filetype)
        return hl
    end,
}

M.FileLastModified = {
    provider = function()
        local ftime = vim.fn.getftime(vim.api.nvim_buf_get_name(0))
        return (ftime > 0) and os.date('%c', ftime)
    end,
}

M.FileFormat = {
    provider = function()
        local fmt = vim.bo.fileformat or 'unix'
        return fmt ~= 'unix' and fmt:upper()
    end,
}

M.FileEncoding = {
    provider = function()
        local enc = vim.bo.fenc or vim.o.enc --[[@as string]]
        return enc:upper()
    end,
    hl = { bold = true },
}

M.Ruler = {
    provider = ' %c  %l',
}

M.Percent = {
    provider = '%P',
}

M.ScrollBar = {
    static = {
        sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' },
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_line_count(0)
        local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
        return string.rep(self.sbar[i], 2)
    end,
    hl = { fg = 'gray' },
}

M.LSPActive = {
    condition = conditions.lsp_attached,
    update = { 'LspAttach', 'LspDetach', 'WinResized' },

    hl = { fg = 'aqua', bold = true },

    flexible = 1,

    {
        provider = function()
            local names = {}
            for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                table.insert(names, string.format('%s:%s', server.name, server.id))
            end
            return ' [' .. table.concat(names, ' ') .. ']'
        end,
    },
    {

        provider = function()
            local names = {}
            for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                table.insert(names, server.name)
            end
            return ' [' .. table.concat(names, ' ') .. ']'
        end,
    },
    {
        provider = '',
    },
}

M.Navic = {
    condition = function()
        return require('nvim-navic').is_available()
    end,
    provider = function()
        return require('nvim-navic').get_location()
    end,
}

M.Diagnostics = {
    condition = conditions.has_diagnostics,

    static = {
        error_icon = icons.diagnostic.error,
        warn_icon = icons.diagnostic.warn,
        info_icon = icons.diagnostic.info,
        hint_icon = icons.diagnostic.hint,
    },

    init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    update = { 'DiagnosticChanged', 'BufEnter' },

    M.Space,

    {
        provider = function(self)
            -- 0 is just another output, we can decide to print it or not!
            return self.errors > 0 and (self.error_icon .. self.errors .. ' ')
        end,
        hl = { fg = 'diag_error' },
    },
    {
        provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. ' ')
        end,
        hl = { fg = 'diag_warn' },
    },
    {
        provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. ' ')
        end,
        hl = { fg = 'diag_info' },
    },
    {
        provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = 'diag_hint' },
    },
}

M.Git = {
    condition = conditions.is_git_repo,

    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = (self.status_dict.added or 0) ~= 0 or (self.status_dict.removed or 0) ~= 0 or (self.status_dict.changed or 0) ~= 0
    end,

    { -- git branch name
        provider = function()
            return ' ' .. (vim.b.dotvim_git_head or (' ' .. vim.b.gitsigns_head))
        end,
        hl = { fg = 'green_light', bold = true },
    },
    -- You could handle delimiters, icons and counts similar to Diagnostics
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = '(',
    },
    {
        provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and (icons.git.add .. count)
        end,
        hl = { fg = 'git_add' },
    },
    {
        provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and (icons.git.delete .. count)
        end,
        hl = { fg = 'git_del' },
    },
    {
        provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and (icons.git.change .. count)
        end,
        hl = { fg = 'git_change' },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = ')',
    },
}

M.HelpFileName = {
    condition = function()
        return vim.bo.filetype == 'help'
    end,
    provider = function()
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.fnamemodify(filename, ':t')
    end,
    hl = { fg = 'blue' },
}

M.TerminalName = {
    -- we could add a condition to check that buftype == 'terminal'
    -- or we could do that later (see #conditional-statuslines below)
    provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub('.*:', '')
        return ' ' .. tname
    end,
    hl = { fg = 'blue', bold = true },
}

return M
