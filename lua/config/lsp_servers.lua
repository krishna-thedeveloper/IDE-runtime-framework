return {
    ts_ls = {
        init_options = {
            maxTsServerMemory = 2048,
            tsserver = {
                useSyntaxServer = "never",
            },
        },
        settings = {
            typescript = {
                preferences = {
                    importModuleSpecifier = "relative",
                },
            },
        },
    },
    lua_ls = {
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" },
                },
                workspace = {
                    checkThirdParty = false,
                },
            },
        },
    },
    jsonls = {},
    yamlls = {},
}
