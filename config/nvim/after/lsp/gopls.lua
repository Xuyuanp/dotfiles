return {
    filetypes = { 'go', 'gomod', 'gotmpl' },
    settings = {
        gopls = {
            usePlaceholders = false,
            templateExtensions = { 'tpl', 'yaml' },
            experimentalPostfixCompletions = true,
            semanticTokens = false,
            semanticTokenTypes = {
                string = false,
                keyword = false,
            },
            staticcheck = true,
            vulncheck = 'Imports',
            codelenses = {
                gc_details = true,
                generate = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
            },
            analyses = {
                fieldaligment = true,
                nilness = true,
                shadow = true,
                unusedwrite = true,
                unusedparams = true,
                unusedvariable = true,
                useany = true,
            },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
        },
    },
}
