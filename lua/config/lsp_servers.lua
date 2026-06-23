local typescript = require("config.typescript")

local servers = {}

if typescript.provider == "ts_ls" then
    servers.ts_ls = {
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
    }
end

servers.lua_ls = {
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
}

servers.jsonls = {}
servers.yamlls = {}

return servers
