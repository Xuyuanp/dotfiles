return {
    textDocument = {
        completion = {
            completionItem = {
                commitCharactersSupport = false,
                deprecatedSupport = true,
                documentationFormat = { 'markdown', 'plaintext' },
                insertReplaceSupport = true,
                insertTextModeSupport = {
                    valueSet = { 1 },
                },
                labelDetailsSupport = true,
                preselectSupport = false,
                resolveSupport = {
                    properties = { 'documentation', 'detail', 'additionalTextEdits', 'command', 'data' },
                },
                snippetSupport = true,
                tagSupport = {
                    valueSet = { 1 },
                },
            },
            completionList = {
                itemDefaults = { 'commitCharacters', 'editRange', 'insertTextFormat', 'insertTextMode', 'data' },
            },
            contextSupport = true,
            insertTextMode = 1,
        },
    },
}
