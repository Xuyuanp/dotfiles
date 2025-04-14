return {
    settings = {
        -- https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json
        Lua = {
            codelenses = {
                enable = true,
            },
            hint = {
                enable = true,
            },
            diagnostics = {
                enable = true,
                disable = {
                    'unused-vararg',
                    'redefined-local',
                },
                globals = {
                    'vim',
                    'require',
                    'assert',
                    'print',
                },
                unusedLocalExclude = { '_*', 'self' },
            },
            runtime = {
                version = 'LuaJIT',
            },
        },
    },
}
