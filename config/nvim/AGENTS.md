# Neovim config

This project is a neovim config written in lua. It is designed to be modular and easily customizable.

## Directory structure

```
.
├── after/
│   ├── ftplugin/       # Filetype-specific settings
│   ├── lsp/            # Per-server LSP configs (vim.lsp.config)
│   └── queries/        # Custom treesitter queries
├── indent/             # Custom indent rules
├── lua/dotvim/
│   ├── config/         # Core config modules
│   ├── plugins/        # Plugin specs (lazy.nvim)
│   ├── util/           # Shared utilities
│   ├── autocmds.lua    # Autocommands
│   ├── commands.lua    # User commands
│   ├── features.lua    # Feature flags
│   ├── keymaps.lua     # Key mappings
│   ├── lazy.lua        # lazy.nvim bootstrap
│   ├── mini.lua        # mini.nvim setup
│   ├── neovide.lua     # Neovide-specific config
│   └── settings.lua    # vim.o / vim.g options
├── snippets/           # VSCode-format snippets
├── scripts/            # Dev/helper scripts
├── tests/              # Tests
└── init.lua            # Entry point
```

## Rules

- Commit to main branch is ok.
- All Lua functions and types MUST have LuaCATS type annotations.

## Looking up Neovim APIs

### `:help` docs

Dump the help buffer to a temp file, then use `rg` and `read` to navigate:

```bash
nvim --clean --headless -c 'help <topic>' -c "w! $(mktemp /tmp/nvim-help-XXXXXX.txt)" -c 'qa'
```

- Use `rg` to search within the file, `read` with `offset`/`limit` to paginate
- Each invocation creates a unique file, so multiple topics can be cross-referenced
- Always use `--clean` to avoid plugin interference

### Lua source in `$VIMRUNTIME`

When unsure about a Neovim Lua API (signatures, behavior, implementation),
search the source files in `$VIMRUNTIME` directly.

Resolve the runtime path:

```bash
nvim --headless -c 'echo $VIMRUNTIME' -c 'qa' 2>&1
```

Then search the Lua sources:

```bash
rg 'pattern' <VIMRUNTIME>/lua
```

This is the authoritative source for built-in Lua modules (`vim.net`, `vim.lsp`,
`vim.treesitter`, etc.) and is more reliable than guessing from memory.
