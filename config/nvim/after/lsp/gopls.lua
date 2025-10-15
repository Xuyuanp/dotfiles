return {
    filetypes = { 'go', 'gomod', 'gotmpl' },
    settings = {
        gopls = {
            usePlaceholders = false,
            templateExtensions = { 'tpl', 'yaml' },
            experimentalPostfixCompletions = true,
            gofumpt = true,
            semanticTokens = false,
            staticcheck = false, -- leave for golangci-lint
            vulncheck = 'Imports',
            codelenses = {
                gc_details = true,
                generate = true,
                vulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
            },
            analyses = {
                shadow = true,
                appendclipped = true,
                slicesdelete = true,
                any = false,
            },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
                ignoredError = true,
            },
        },
    },
}
