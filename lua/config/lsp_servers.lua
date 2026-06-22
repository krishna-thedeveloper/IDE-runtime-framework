return {
    ts_ls = {
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
