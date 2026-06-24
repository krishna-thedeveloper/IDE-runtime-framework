--- Worst-case benchmark runner
-- Run: nvim --headless -c "luafile bench/worst.lua" -c "qa!"

local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")
local bench_dir = lib.bench_dir
local proj_dir = bench_dir .. "/projects/worstcase"
local results_dir = bench_dir .. "/results"

os.execute("mkdir -p " .. results_dir)
local outfile = results_dir .. "/worstcase.log"

local t_start = vim.uv.hrtime()

vim.wait(15000, function() return vim.fn.exists(":Lazy") == 2 end, 500)

local engines = require("managers.language_engine")
local active_engine = engines.get("typescript")
local is_ts_ls = active_engine == "ts_ls"
local is_ts_tools = active_engine == "typescript_tools"

io.write(string.format("Active engine: %s\n\n", active_engine))

lib.measure("1-STARTUP (no files)", t_start)

vim.cmd("e " .. proj_dir .. "/src/generated/massive-file.ts")
local ts_attach_start = vim.uv.hrtime()
vim.bo.filetype = "typescript"

local client_name = is_ts_ls and "ts_ls" or "typescript-tools"
lib.wait_for_client(client_name, 30000)
io.write(string.format("  %s attach time: %d ms\n", client_name, lib.elapsed_ms(ts_attach_start)))

io.write("  Waiting 30s for tsserver to index project...\n")
vim.wait(30000)

lib.measure("2-STABLE (worst-case project loaded)", t_start)

io.write("\n--- WORST CASE: 50 type errors ---\n")
vim.cmd("e " .. proj_dir .. "/src/generated/error-bomb.ts")
vim.bo.filetype = "typescript"
vim.wait(2000)

for i = 1, 10 do
  local diags = vim.diagnostic.get(0)
  io.write(string.format("  t=%ds: %d diagnostics\n", i * 2, #diags))
  vim.wait(2000)
end

io.write("\n--- WORST CASE: completion inside deep generic ---\n")
vim.cmd("e " .. proj_dir .. "/src/types/complex-generics.ts")
vim.bo.filetype = "typescript"
vim.wait(3000)

local buf = vim.fn.bufnr("%")
lib.completion_latency(buf, 2, 10, "DeepPartial<T> (generic)")
lib.completion_latency(buf, 49, 15, "UnionToIntersection<U> (complex generic)")
lib.hover_latency(buf, 1, 10, "DeepPartial type reference")
lib.hover_latency(buf, 49, 10, "UnionToIntersection type reference")

io.write("\n--- WORST CASE: rapid file switching ---\n")
local files = {
  proj_dir .. "/src/generated/massive-file.ts",
  proj_dir .. "/src/generated/error-bomb.ts",
  proj_dir .. "/src/generated/index.ts",
  proj_dir .. "/src/generated/chain_a.ts",
  proj_dir .. "/src/generated/chain_j.ts",
  proj_dir .. "/src/generated/circular_a.ts",
  proj_dir .. "/src/generated/circular_b.ts",
  proj_dir .. "/src/types/complex-generics.ts",
  proj_dir .. "/src/generated/massive-file.ts",
  proj_dir .. "/src/generated/error-bomb.ts",
}
local switch_times = {}
for idx, f in ipairs(files) do
  local s = vim.uv.hrtime()
  vim.cmd("e " .. f)
  vim.bo.filetype = "typescript"
  vim.wait(500)
  local elapsed = lib.elapsed_ms(s)
  table.insert(switch_times, elapsed)
  io.write(string.format("  switch %d: %d ms\n", idx, elapsed))
end
local avg_switch = 0
for _, t in ipairs(switch_times) do avg_switch = avg_switch + t end
avg_switch = avg_switch / #switch_times
io.write(string.format("  avg switch: %.0f ms\n", avg_switch))

lib.measure("3-ACTIVE (worst-case: errors+completions+switches)", t_start)

io.write("\n  Idle 60s with error-bomb open...\n")
vim.cmd("e " .. proj_dir .. "/src/generated/error-bomb.ts")
vim.bo.filetype = "typescript"
vim.wait(60000)
lib.measure("4-IDLE (60s with error-bomb open)", t_start)

local clients = vim.lsp.get_clients()
io.write(string.format("\n  Final LSP clients: %d\n", #clients))
for _, c in ipairs(clients) do
  io.write(string.format("    - %s (attached: %s)\n", c.name, tostring(c.attached)))
end

vim.defer_fn(function() vim.cmd("qall!") end, 1000)
