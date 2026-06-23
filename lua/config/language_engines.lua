-- Define languages with switchable engines.
-- Add new entries here as other languages gain alternative providers.
return {
  typescript = {
    default = "ts_ls",
    providers = { "ts_ls", "typescript_tools" },
  },
}
