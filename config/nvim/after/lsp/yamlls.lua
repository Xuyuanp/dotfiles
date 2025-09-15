return {
    settings = {
        yaml = {
            schemaStore = {
                enable = false,
                url = '',
            },
            schemas = require('schemastore').yaml.schemas(),

            format = {
                enable = false, -- use yamlfmt of none-ls instead
            },
        },
    },
}
