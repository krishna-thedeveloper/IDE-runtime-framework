--- Engine Switching & Lifecycle Tests
--- Measures cleanup correctness, orphan detection, memory growth across switching cycles
--- Usage: nvim --headless -c "lua require('bench.scripts.engine_switching_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local MANAGERS = { "lazy", "pckr", "mini_deps", "vim_pack" }
local LSP_ENGINES = { "ts_ls", "typescript_tools" }
local THEMES = { "catppuccin", "tokyonight", "kanagawa", "onedark" }

function M.run(opts)
  opts = opts or {}
  local switch_cycles = opts.cycles or 100
  local ctx = rm.create_run({
    benchmark = "engine_switching",
    switch_cycles = switch_cycles,
  })
  ctx:open_log("engine_switching")

  local proj_dir = rm.bench_dir .. "/projects"
  ctx:log("=== Engine Switching & Lifecycle Tests ===")
  ctx:log(string.format("Switch cycles: %d", switch_cycles))
  ctx:log("")

  --- Lifecycle baseline: collect initial state
  local function collect_lifecycle_state(label)
    local clients = vim.lsp.get_clients()
    local procs = lib.process_tree()
    local ac_total, ac_events = lib.count_autocmds()
    local timers = lib.count_timers()
    local modules = lib.count_modules()
    local nvim_rss = lib.nvim_rss_kb()
    local gc_kb = math.floor(collectgarbage("count"))

    for _, c in ipairs(clients) do
      ctx:record("lifecycle_" .. label, c.name, {
        pid = c.rpc and c.rpc.pid or 0,
        attached_bufs = #c.attached_buffers,
      })
    end

    ctx:record("lifecycle_" .. label, "summary", {
      clients = #clients,
      child_processes = #procs,
      autocmds = ac_total,
      timers = timers,
      modules = modules,
      nvim_rss_kb = nvim_rss,
      gc_kb = gc_kb,
    })

    ctx:log(string.format("  %s: clients=%d procs=%d autocmds=%d timers=%d modules=%d rss=%dKB",
      label, #clients, #procs, ac_total, timers, modules, nvim_rss))
  end

  --- 1. Theme switching cycles
  ctx:log("--- 1. Theme Switching (%d cycles) ---", switch_cycles)
  collect_lifecycle_state("before_theme_switching")

  local theme_switch_times = {}
  for i = 1, math.min(switch_cycles, 500) do
    local theme = THEMES[(i % #THEMES) + 1]
    local start = lib.hrtime()
    pcall(vim.cmd, "colorscheme " .. theme)
    table.insert(theme_switch_times, lib.elapsed_ms(start))
    if i % 100 == 0 then
      collectgarbage("collect")
      ctx:log(string.format("  Theme switch %d/%d", i, math.min(switch_cycles, 500)))
    end
  end

  local ts_stats = rm.stats(theme_switch_times)
  ctx:record("engine_switching", "theme_switching", {
    cycles = #theme_switch_times,
    avg_ms = ts_stats.avg,
    median_ms = ts_stats.median,
    min_ms = ts_stats.min,
    max_ms = ts_stats.max,
    p95_ms = ts_stats.p95,
  })
  ctx:log(string.format("  Theme switching: avg=%.1fms median=%.0fms p95=%.0fms",
    ts_stats.avg, ts_stats.median, ts_stats.p95))

  collect_lifecycle_state("after_theme_switching")

  --- 2. LSP engine switching (ts_ls <-> typescript_tools)
  ctx:log("\n--- 2. LSP Engine Switching (%d cycles) ---", math.min(switch_cycles, 100))
  collect_lifecycle_state("before_lsp_switching")

  local engines_mod = require("managers.language_engine")
  local lsp_switch_times = {}
  for i = 1, math.min(switch_cycles, 100) do
    local engine = LSP_ENGINES[(i % #LSP_ENGINES) + 1]
    local start = lib.hrtime()
    engines_mod.set("typescript", engine)
    table.insert(lsp_switch_times, lib.elapsed_ms(start))
    vim.wait(100)
  end

  if #lsp_switch_times > 0 then
    local ls_stats = rm.stats(lsp_switch_times)
    ctx:record("engine_switching", "lsp_switching", {
      cycles = #lsp_switch_times,
      avg_ms = ls_stats.avg,
      median_ms = ls_stats.median,
      min_ms = ls_stats.min,
      max_ms = ls_stats.max,
      p95_ms = ls_stats.p95,
    })
    ctx:log(string.format("  LSP switching: avg=%.1fms median=%.0fms p95=%.0fms",
      ls_stats.avg, ls_stats.median, ls_stats.p95))
  end

  collect_lifecycle_state("after_lsp_switching")

  --- 3. Open/close file cycles with LSP
  ctx:log("\n--- 3. File Open/Close Cycles (%d) ---", math.min(switch_cycles, 200))
  local file_cycle_times = {}
  for i = 1, math.min(switch_cycles, 200) do
    local start = lib.hrtime()
    vim.cmd("e " .. proj_dir .. "/large/src/file_" .. string.format("%04d.ts", (i % 1000) + 1))
    vim.bo.filetype = "typescript"
    vim.wait(200)
    vim.cmd("%bdelete!")
    vim.wait(100)
    table.insert(file_cycle_times, lib.elapsed_ms(start))
  end

  local fc_stats = rm.stats(file_cycle_times)
  ctx:record("engine_switching", "file_open_close", {
    cycles = #file_cycle_times,
    avg_ms = fc_stats.avg,
    median_ms = fc_stats.median,
    min_ms = fc_stats.min,
    max_ms = fc_stats.max,
    p95_ms = fc_stats.p95,
  })
  ctx:log(string.format("  File open/close: avg=%.1fms median=%.0fms p95=%.0fms",
    fc_stats.avg, fc_stats.median, fc_stats.p95))

  collect_lifecycle_state("after_file_cycles")

  --- 4. Orphan detection
  ctx:log("\n--- 4. Orphan Detection ---")
  local all_processes = lib.process_tree()
  local orphans = {}
  for _, p in ipairs(all_processes) do
    if p.rss == 0 or p.comm:match("defunct") or p.comm:match("zombie") then
      table.insert(orphans, p)
    end
  end

  ctx:record("lifecycle_orphans", "detection", {
    total_children = #all_processes,
    orphans = #orphans,
    zombie_count = #orphans,
  })
  if #orphans > 0 then
    ctx:log(string.format("  WARNING: %d orphan/zombie processes detected!", #orphans))
    for _, p in ipairs(orphans) do
      ctx:log(string.format("    pid=%d rss=%d comm=%s", p.pid, p.rss, p.comm))
    end
  else
    ctx:log("  No orphan processes detected.")
  end

  --- 5. Memory leak detection
  ctx:log("\n--- 5. Memory Growth Analysis ---")
  local mem_samples = {}
  for i = 1, 10 do
    collectgarbage("collect")
    local rss_kb = lib.nvim_rss_kb()
    local gc_kb = collectgarbage("count")
    table.insert(mem_samples, { rss_kb = rss_kb, gc_kb = gc_kb })
    vim.wait(500)
  end

  local first_rss = mem_samples[1].rss_kb
  local last_rss = mem_samples[#mem_samples].rss_kb
  local growth = last_rss - first_rss
  ctx:record("lifecycle_memory", "growth_analysis", {
    initial_rss_kb = first_rss,
    final_rss_kb = last_rss,
    growth_kb = growth,
    growth_percent = (growth / first_rss) * 100,
    samples = #mem_samples,
  })
  ctx:log(string.format("  Memory: initial=%dKB final=%dKB growth=%dKB (%.1f%%)",
    first_rss, last_rss, growth, (growth / first_rss) * 100))

  if growth > first_rss * 0.1 then
    ctx:log("  WARNING: Possible memory leak (>10% growth)")
  end

  local final = ctx:finalize()
  return final
end

return M
