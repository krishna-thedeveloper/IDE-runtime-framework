--- Comprehensive full IDE benchmark runner
-- Run: nvim --headless -c "luafile bench/run.lua [flow_name]" -c "qa!"
-- flow_name: "ts_ls" or "typescript_tools"

local flow_name = arg and arg[1] or "unknown"
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")
local bench_dir = lib.bench_dir
local proj_dir = bench_dir .. "/projects"
local results_dir = bench_dir .. "/results"

os.execute("mkdir -p " .. results_dir)

local outfile = results_dir .. "/" .. flow_name .. ".log"
local rf = io.open(outfile, "w")
local function log(...)
  local args = {...}
  for i, v in ipairs(args) do args[i] = tostring(v) end
  local line = table.concat(args, " ") .. "\n"
  io.write(line)
  rf:write(line)
  rf:flush()
  io.flush()
end

log("=== Full IDE Benchmark: Flow " .. flow_name .. " ===")
log("Date:", os.date())
log("Engine:", require("managers.language_engine").get("typescript") or "unknown")
log("Bench dir:", bench_dir)
log("")

local t0 = lib.hrtime()

local function settle(ms)
  vim.wait(ms)
  collectgarbage("collect")
end

--=============================================================================
-- 1) STARTUP / BASELINE
--=============================================================================
log("=== 1. STARTUP BASELINE ===")
local startup_snap = lib.measure("1a-POST-STARTUP", t0)

local autocmd_count, autocmd_by_event = lib.count_autocmds()
log(string.format("  autocmds: %d", autocmd_count))
for ev, cnt in pairs(autocmd_by_event) do
  if cnt > 5 then
    log(string.format("    %s: %d handlers", ev, cnt))
  end
end

local timer_count = lib.count_timers()
log(string.format("  timers: %d", timer_count))

local proc_tree = lib.process_tree()
log(string.format("  child processes: %d", #proc_tree))
for _, p in ipairs(proc_tree) do
  log(string.format("    [depth=%d] pid=%d rss=%s MB vsz=%s MB | %s",
    p.depth, p.pid, lib.bytes_to_mb(p.rss), lib.bytes_to_mb(p.vsz), p.comm))
end

--=============================================================================
-- 2) PLUGIN ANALYSIS
--=============================================================================
log("\n=== 2. PLUGIN ANALYSIS ===")

local lazy_stats = {}
local ok, lazy = pcall(require, "lazy")
if ok and lazy.stats then
  lazy_stats = lazy.stats()
  log(string.format("  lazy.nvim loaded plugins: %d", #lazy_stats))
  if #lazy_stats == 0 then
    local loaded = 0
    for mod, _ in pairs(package.loaded) do
      if type(mod) == "string" and (mod:match("^plugins") or mod:match("^lazy")) then
        loaded = loaded + 1
      end
    end
    log(string.format("  (loaded plugin modules count: %d)", loaded))
  end
end

if #lazy_stats > 0 then
  table.sort(lazy_stats, function(a, b) return (a.loading_time or 0) > (b.loading_time or 0) end)
  log("  Top 10 slowest plugins:")
  for i = 1, math.min(10, #lazy_stats) do
    local s = lazy_stats[i]
    log(string.format("    %d. %s: %.1f ms", i, s.name, s.loading_time or 0))
  end

  log("  Top 10 memory consumers:")
  table.sort(lazy_stats, function(a, b) return (a.memory or 0) > (b.memory or 0) end)
  for i = 1, math.min(10, #lazy_stats) do
    local s = lazy_stats[i]
    log(string.format("    %d. %s: %d KB", i, s.name, s.memory or 0))
  end

  log("  Full plugin table:")
  for _, s in ipairs(lazy_stats) do
    log(string.format("    %s|%.1f ms|%d KB|%s", s.name, s.loading_time or 0, s.memory or 0, s.event or ""))
  end
end

--=============================================================================
-- 3) COMPONENT BENCHMARKS
--=============================================================================
log("\n=== 3. COMPONENT BENCHMARKS ===")

log("--- 3a. Treesitter ---")
local ts_ok, ts_parsers = pcall(require, "nvim-treesitter")
if ts_ok then
  log("  nvim-treesitter loaded")
end

local parsed_langs = {}
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  local ok2, ts = pcall(vim.treesitter.get_parser, buf)
  if ok2 and ts then
    for lang, _ in pairs(ts:children() or {}) do
      parsed_langs[lang] = (parsed_langs[lang] or 0) + 1
    end
  end
end
for lang, count in pairs(parsed_langs) do
  log(string.format("  treesitter: %s (%d buffers)", lang, count))
end

local ts_mem = collectgarbage("count") - startup_snap.gc_kb
log(string.format("  treesitter Lua memory delta: %.0f KB", ts_mem))

local ts_f = proj_dir .. "/large/src/file_0500.ts"
local ts_buf = vim.fn.bufadd(ts_f)
vim.fn.bufload(ts_buf)
vim.bo[ts_buf].filetype = "typescript"

local parse_start = lib.hrtime()
local ok_parse, parser = pcall(vim.treesitter.get_parser, ts_buf, "typescript")
if ok_parse and parser then
  parser:parse()
  local parse_ms = lib.elapsed_ms(parse_start)
  log(string.format("  treesitter parse TypeScript (500-line file): %d ms", parse_ms))

  local hi_start = lib.hrtime()
  local ok_hi, hi = pcall(vim.treesitter.highlighter.new, ts_buf)
  local hi_ms = lib.elapsed_ms(hi_start)
  log(string.format("  treesitter highlighter init: %d ms (ok=%s)", hi_ms, tostring(ok_hi)))
else
  log(string.format("  treesitter parser not available (ok=%s, parser=%s)", tostring(ok_parse), tostring(parser)))
end

log("--- 3b. Completion Engine ---")
local cmp_ok, cmp = pcall(require, "cmp")
if cmp_ok then
  log("  nvim-cmp loaded")
  local sources = {}
  for _, s in ipairs(cmp.get_sources() or {}) do
    table.insert(sources, s.name)
  end
  log(string.format("  completion sources: %s", table.concat(sources, ", ")))
end

local picker_name = nil
local picker_ok, _ = pcall(require, "telescope")
if picker_ok then picker_name = "telescope" end
if not picker_name then
  picker_ok, _ = pcall(require, "snacks")
  if picker_ok then picker_name = "snacks" end
end
if not picker_name then
  picker_ok, _ = pcall(require, "fzf-lua")
  if picker_ok then picker_name = "fzf-lua" end
end
log(string.format("  search picker: %s", picker_name or "none"))

local statusline_name = nil
if pcall(require, "lualine") then statusline_name = "lualine" end
if not statusline_name and pcall(require, "galaxyline") then statusline_name = "galaxyline" end
if not statusline_name and pcall(require, "feline") then statusline_name = "feline" end
log(string.format("  statusline: %s", statusline_name or "built-in"))

if pcall(require, "bufferline") then log("  bufferline: loaded") end
if pcall(require, "indent-blankline") then log("  indent-blankline: loaded") end
if pcall(require, "notify") then log("  notify: loaded") end

--=============================================================================
-- 4) LSP BENCHMARKS
--=============================================================================
log("\n=== 4. LSP BENCHMARKS ===")

local all_clients = vim.lsp.get_clients()
log(string.format("  LSP clients at start: %d", #all_clients))
for _, c in ipairs(all_clients) do
  log(string.format("    - %s", c.name))
end

log("--- 4a. TypeScript LSP ---")
local ts_client_name = flow_name == "ts_ls" and "ts_ls" or "typescript-tools"

vim.cmd("e " .. proj_dir .. "/large/src/file_0500.ts")
vim.bo.filetype = "typescript"
local ts_attached = lib.wait_for_client(ts_client_name, 30000)
log(string.format("  %s attached: %s (%d ms)", ts_client_name, ts_attached, lib.elapsed_ms(t0)))

log("  Waiting 15s for project indexing...")
settle(15000)
lib.measure("4a-TypeScript-STABLE", t0)

local buf = vim.fn.bufnr("%")
lib.completion_latency(buf, 1, 5, "TypeScript basic completion")
lib.hover_latency(buf, 3, 10, "DataType hover")
lib.definition_latency(buf, 3, 10, "DataType definition")
lib.reference_latency(buf, 3, 10, "DataType references")
lib.rename_latency(buf, 3, 10, "DataRenamed", "DataType rename")

vim.fn.chdir(proj_dir .. "/large")
vim.wait(5000)
local diags = vim.diagnostic.get(buf)
log(string.format("  diagnostics: %d total", #diags))
local diag_counts = {}
for _, d in ipairs(diags) do
  diag_counts[d.severity] = (diag_counts[d.severity] or 0) + 1
end
for sev, cnt in pairs(diag_counts) do
  local sev_name = ({ "ERROR", "WARN", "INFO", "HINT" })[sev] or tostring(sev)
  log(string.format("    %s: %d", sev_name, cnt))
end

log("--- 4b. LuaLS ---")
local lua_buf = vim.fn.bufadd(bench_dir .. "/lib.lua")
vim.fn.bufload(lua_buf)
vim.bo[lua_buf].filetype = "lua"
local lua_attached = lib.wait_for_client("lua_ls", 15000)
log(string.format("  LuaLS attached: %s", lua_attached))
if lua_attached then
  settle(3000)
  lib.completion_latency(lua_buf, 1, 5, "LuaLS completion")
  lib.hover_latency(lua_buf, 1, 5, "LuaLS hover")
end

log("--- 4c. JSONLS ---")
local json_buf = vim.fn.bufadd(proj_dir .. "/large/tsconfig.json")
vim.fn.bufload(json_buf)
vim.bo[json_buf].filetype = "json"
local json_attached = lib.wait_for_client("jsonls", 15000)
log(string.format("  JSONLS attached: %s", json_attached))
if json_attached then
  settle(3000)
  lib.completion_latency(json_buf, 1, 2, "JSONLS completion")
  lib.hover_latency(json_buf, 1, 2, "JSONLS hover")
end

lib.measure("4d-LSP-COMBINED", t0)
log(string.format("  clients now: %d", #vim.lsp.get_clients()))

--=============================================================================
-- 5) PROJECT SIZE SCENARIOS
--=============================================================================
log("\n=== 5. PROJECT SIZE SCENARIOS ===")

local projects = {
  { name = "small",  path = proj_dir .. "/small" },
  { name = "medium", path = proj_dir .. "/medium" },
  { name = "large",  path = proj_dir .. "/large" },
}

vim.cmd("%bdelete!")

for _, proj in ipairs(projects) do
  log(string.format("--- Project: %s ---", proj.name))
  vim.fn.chdir(proj.path)
  vim.cmd("e src/file_0001.ts")
  vim.bo.filetype = "typescript"
  settle(5000)

  lib.measure(string.format("5-%s-STABLE", proj.name), t0)

  local buf2 = vim.fn.bufnr("%")
  lib.completion_latency(buf2, 1, 5, string.format("%s completion", proj.name))
  lib.hover_latency(buf2, 3, 10, string.format("%s hover", proj.name))

  local file_count = #vim.fn.globpath(proj.path .. "/src", "*.ts", false, true)
  log(string.format("  files in project: %d", file_count))
end

log("--- Project: huge ---")
vim.cmd("%bdelete!")
vim.fn.chdir(proj_dir .. "/huge")
vim.cmd("e src/file_05000.ts")
vim.bo.filetype = "typescript"
settle(15000)
lib.measure("5-huge-PARTIAL", t0)
local huge_buf = vim.fn.bufnr("%")
lib.completion_latency(huge_buf, 1, 5, "huge completion")
lib.hover_latency(huge_buf, 1, 5, "huge hover")

log("--- Project: monorepo ---")
vim.cmd("%bdelete!")
vim.fn.chdir(proj_dir .. "/monorepo")
vim.cmd("e packages/core/src/module_001.ts")
vim.bo.filetype = "typescript"
settle(5000)
lib.measure("5-monorepo-STABLE", t0)
local mono_buf = vim.fn.bufnr("%")
lib.completion_latency(mono_buf, 1, 5, "monorepo completion")

--=============================================================================
-- 6) FILE SCENARIOS
--=============================================================================
log("\n=== 6. FILE SCENARIOS ===")

local file_counts = { 1, 5, 10, 25, 50, 100 }
for _, n in ipairs(file_counts) do
  log(string.format("--- Opening %d files ---", n))
  vim.cmd("%bdelete!")
  collectgarbage("collect")
  local snap_before = lib.snapshot()

  for i = 1, math.min(n, 1000) do
    local fn = string.format(proj_dir .. "/large/src/file_%04d.ts", i)
    local b = vim.fn.bufadd(fn)
    vim.fn.bufload(b)
    vim.bo[b].filetype = "typescript"
  end

  settle(5000)
  local snap_after = lib.snapshot()
  local mem_delta = (snap_after.grand_rss - snap_before.grand_rss) / 1024 / 1024
  log(string.format("  %d files: nvim=%d MB lsp=%d MB total=%d MB delta=%.1f MB",
    n,
    math.floor(snap_after.nvim_rss / 1024),
    math.floor(snap_after.lsp_rss / 1024 / 1024),
    math.floor(snap_after.grand_rss / 1024 / 1024),
    mem_delta))
end

--=============================================================================
-- 7) ACTIVE WORST-CASE
--=============================================================================
log("\n=== 7. WORST-CASE TESTS ===")

vim.cmd("%bdelete!")
collectgarbage("collect")

log("--- 7a. Rapid file switching ---")
local switch_files = {}
for i = 1, 50 do
  table.insert(switch_files, string.format(proj_dir .. "/large/src/file_%04d.ts", i))
end
local switch_times = {}
for _, fn in ipairs(switch_files) do
  local s = lib.hrtime()
  vim.cmd("e " .. fn)
  vim.bo.filetype = "typescript"
  vim.wait(100)
  local elapsed = lib.elapsed_ms(s)
  table.insert(switch_times, elapsed)
end
table.sort(switch_times)
local switch_avg = 0; for _, t in ipairs(switch_times) do switch_avg = switch_avg + t end
switch_avg = switch_avg / #switch_times
log(string.format("  rapid switch (50 files): avg=%.0fms min=%dms max=%dms median=%dms p95=%dms",
  switch_avg, switch_times[1], switch_times[#switch_times],
  switch_times[math.ceil(#switch_times/2)],
  switch_times[math.ceil(#switch_times * 0.95)]))

log("--- 7b. Worst-case project (complex generics + errors) ---")
local wc_dir = proj_dir .. "/worstcase"
if vim.fn.isdirectory(wc_dir) == 1 then
  vim.fn.chdir(wc_dir)
  vim.cmd("e src/generated/massive-file.ts")
  vim.bo.filetype = "typescript"
  settle(10000)
  lib.measure("7b-WORST-CASE-LOADED", t0)

  vim.cmd("e src/generated/error-bomb.ts")
  vim.bo.filetype = "typescript"
  settle(5000)
  local eb_buf = vim.fn.bufnr("%")
  for i = 1, 5 do
    local d = vim.diagnostic.get(eb_buf)
    log(string.format("  t=%ds: %d diagnostics", i * 2, #d))
    settle(2000)
  end
  lib.measure("7b-WORST-CASE-ERRORS", t0)
end

log("--- 7c. All LSPs active ---")
vim.cmd("e " .. bench_dir .. "/lib.lua")
vim.bo.filetype = "lua"
vim.cmd("e " .. proj_dir .. "/large/tsconfig.json")
vim.bo.filetype = "json"
settle(10000)
lib.measure("7c-ALL-LSPS-ACTIVE", t0)

--=============================================================================
-- 8) IDLE & STABILITY
--=============================================================================
log("\n=== 8. IDLE & STABILITY ===")

log("--- 8a. Memory snapshot ---")
vim.cmd("%bdelete!")
collectgarbage("collect")
settle(3000)
lib.measure("8a-POST-CLEANUP", t0)

log("--- 8b. 5-minute idle ---")
local idle_start = lib.hrtime()
for i = 1, 5 do
  settle(60000)
  lib.measure(string.format("8b-IDLE-%dmin", i), t0)

  local ac, events = lib.count_autocmds()
  log(string.format("  autocmds: %d", ac))

  local tree = lib.process_tree()
  log(string.format("  child processes: %d", #tree))
  for _, p in ipairs(tree) do
    if p.rss == 0 then
      log(string.format("    ZOMBIE: pid=%d %s", p.pid, p.comm))
    end
  end

  local tc = lib.count_timers()
  log(string.format("  timers: %d", tc))

  local client_names = {}
  for _, c in ipairs(vim.lsp.get_clients()) do
    client_names[c.name] = (client_names[c.name] or 0) + 1
  end
  for name, count in pairs(client_names) do
    if count > 1 then
      log(string.format("  DUPLICATE LSP: %s appears %d times", name, count))
    end
  end
end

log("--- 8c. GC pressure ---")
local gc_before = collectgarbage("count")
collectgarbage("collect")
local gc_after = collectgarbage("count")
log(string.format("  GC freed: %.0f KB (was %.0f KB, now %.0f KB)", gc_before - gc_after, gc_before, gc_after))

--=============================================================================
-- 9) FINAL STATE
--=============================================================================
log("\n=== 9. FINAL STATE ===")
lib.measure("9-FINAL", t0)

local module_categories = {}
for mod, _ in pairs(package.loaded) do
  if type(mod) == "string" then
    local cat = mod:match("^([^.]+)") or "other"
    module_categories[cat] = (module_categories[cat] or 0) + 1
  end
end
log("\nModule categories:")
for cat, cnt in pairs(module_categories) do
  if cnt > 5 then
    log(string.format("  %s: %d modules", cat, cnt))
  end
end
log(string.format("  (other categories omitted, total=%d)", lib.count_modules()))

--=============================================================================
log(string.format("\n=== Benchmark complete. Total duration: %d seconds ===",
  lib.elapsed_ms(t0) / 1000))

rf:close()
print(string.format("\nFull results: %s", outfile))
