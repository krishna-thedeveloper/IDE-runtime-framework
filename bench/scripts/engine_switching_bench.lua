--- Engine Switching & Lifecycle Tests
--- Measures real LSP lifecycle: attach, operations, stop, cleanup, cycling, load
--- Usage: nvim --headless -c "lua require('bench.scripts.engine_switching_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}
local MANAGERS = { "lazy", "pckr", "mini_deps", "vim_pack" }
local THEMES = { "catppuccin", "tokyonight", "kanagawa", "onedark" }

local function collect_state(label)
  local clients = vim.lsp.get_clients()
  local procs = lib.process_tree()
  local ac_total = lib.count_autocmds()
  local modules = lib.count_modules()
  local snap = lib.snapshot()
  local gc_kb = math.floor(collectgarbage("count"))
  return {
    label = label,
    clients = clients,
    n_clients = #clients,
    procs = procs,
    n_procs = #procs,
    autocmds = ac_total,
    modules = modules,
    nvim_rss = snap.nvim_rss,
    lsp_rss = snap.lsp_rss,
    grand_rss = snap.grand_rss,
    gc_kb = gc_kb,
    cpu = snap.cpu,
  }
end

local function log_state(ctx, s)
  ctx:log(string.format("  %s: clients=%d children=%d autocmds=%d modules=%d nvim=%dMB lsp=%dMB total=%dMB cpu=%.1f%%",
    s.label, s.n_clients, s.n_procs, s.autocmds, s.modules,
    math.floor(s.nvim_rss/1024/1024), math.floor(s.lsp_rss/1024/1024),
    math.floor(s.grand_rss/1024/1024), s.cpu))

  for _, c in ipairs(s.clients) do
    ctx:record("lifecycle_" .. s.label, c.name, {
      pid = c.rpc and c.rpc.pid or 0,
      attached_bufs = #(c.attached_buffers or {}),
    })
  end
  ctx:record("lifecycle_" .. s.label, "summary", {
    clients = s.n_clients, child_processes = s.n_procs,
    autocmds = s.autocmds, modules = s.modules,
    nvim_rss_kb = math.floor(s.nvim_rss/1024),
    lsp_rss_kb = math.floor(s.lsp_rss/1024),
    grand_rss_kb = math.floor(s.grand_rss/1024),
    gc_kb = s.gc_kb, cpu = s.cpu,
  })
end

local function open_ts_file(proj_path)
  local buf = vim.fn.bufadd(proj_path .. "/src/index.ts")
  vim.fn.bufload(buf)
  vim.bo[buf].filetype = "typescript"
  vim.wait(500)
  return buf
end

local function measure_lsp_op(buf, method, params, timeout_ms)
  timeout_ms = timeout_ms or 10000
  local start = lib.hrtime()
  local done = false
  local result
  vim.lsp.buf_request(buf, method, params, function(err, res)
    result = { err = err, res = res }; done = true
  end)
  vim.wait(timeout_ms, function() return done end, 50)
  return lib.elapsed_ms(start), result
end

local function start_lsp(ctx, proj_path, engine_name, timeout_ms)
  timeout_ms = timeout_ms or 30000
  local start = lib.hrtime()
  local buf = open_ts_file(proj_path)
  local attached = lib.wait_for_client(engine_name, timeout_ms)
  local ms = lib.elapsed_ms(start)
  if attached then vim.wait(2000) end
  return attached, ms, buf
end

local function stop_lsp(engine_name)
  for _, c in ipairs(vim.lsp.get_clients()) do
    if c.name == engine_name then c:stop() end
  end
  vim.wait(1500)
end

local function check_orphans()
  local all_procs = lib.process_tree()
  local orphans = {}
  for _, p in ipairs(all_procs) do
    if p.rss == 0 or (p.comm and (p.comm:match("defunct") or p.comm:match("zombie"))) then
      table.insert(orphans, p)
    end
  end
  return orphans, all_procs
end

function M.run(opts)
  opts = opts or {}
  local switch_cycles = opts.cycles or 50
  local ctx = rm.create_run({ benchmark = "engine_switching", switch_cycles = switch_cycles }, "switching")
  ctx:open_log("engine_switching")

  local proj_dir = rm.bench_dir .. "/projects"
  local proj_path = proj_dir .. "/small"
  local TS_CLIENT = "ts_ls"
  local ALT_CLIENT = "typescript-tools"

  ctx:log("=== Engine Switching & Lifecycle Tests ===\n")

  -- =========================================================================
  -- 1. THEME SWITCHING (unchanged, works correctly)
  -- =========================================================================
  ctx:log("--- 1. Theme Switching (%d cycles) ---", switch_cycles)
  local s0 = collect_state("before_theme_switching"); log_state(ctx, s0)

  local theme_times = {}
  for i = 1, math.min(switch_cycles, 200) do
    local theme = THEMES[(i % #THEMES) + 1]
    local start = lib.hrtime()
    pcall(vim.cmd, "colorscheme " .. theme)
    table.insert(theme_times, lib.elapsed_ms(start))
    if i % 50 == 0 then ctx:log(string.format("  Theme switch %d/%d", i, math.min(switch_cycles, 200))) end
  end

  local ts_stats = rm.stats(theme_times)
  ctx:record("engine_switching", "theme_switching", {
    cycles = #theme_times, avg_ms = ts_stats.avg, median_ms = ts_stats.median,
    min_ms = ts_stats.min, max_ms = ts_stats.max, p95_ms = ts_stats.p95,
  })
  ctx:log(string.format("  Theme switching: avg=%.1fms median=%.0fms p95=%.0fms", ts_stats.avg, ts_stats.median, ts_stats.p95))

  local s1 = collect_state("after_theme_switching"); log_state(ctx, s1)

  -- =========================================================================
  -- 2. LSP ATTACH LIFECYCLE (ts_ls)
  -- =========================================================================
  ctx:log("\n--- 2. LSP Attach Lifecycle (%s) ---", TS_CLIENT)
  local s2_before = collect_state("before_lsp_attach"); log_state(ctx, s2_before)

  -- 2a. First attach
  local attach_start = lib.hrtime()
  local attached, attach_ms, buf1 = start_lsp(ctx, proj_path, TS_CLIENT, 30000)
  local total_attach_ms = lib.elapsed_ms(attach_start)

  if not attached then
    ctx:log("  ERROR: " .. TS_CLIENT .. " did not attach!")
    ctx:record("lifecycle_attach_error", TS_CLIENT, { attached = false })
  else
    local attach_snap = lib.snapshot()
    ctx:record("lifecycle_attach", TS_CLIENT, {
      attached = true, attach_ms = attach_ms, total_startup_ms = total_attach_ms,
      nvim_rss_mb = math.floor(attach_snap.nvim_rss/1024/1024),
      lsp_rss_mb = math.floor(attach_snap.lsp_rss/1024/1024),
      grand_rss_mb = math.floor(attach_snap.grand_rss/1024/1024),
      cpu = attach_snap.cpu,
    })
    ctx:log(string.format("  Attach: %dms (total startup: %dms)", attach_ms, total_attach_ms))
    ctx:log(string.format("  Memory after attach: nvim=%dMB lsp=%dMB total=%dMB",
      math.floor(attach_snap.nvim_rss/1024/1024), math.floor(attach_snap.lsp_rss/1024/1024),
      math.floor(attach_snap.grand_rss/1024/1024)))

    -- 2b. LSP operation measurements
    ctx:log("\n--- 2b. LSP Operations ---")
    local ops = {
      { name = "completion", method = "textDocument/completion", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1),
        position = { line = 10, character = 5 }, context = { triggerKind = 1 } } },
      { name = "hover", method = "textDocument/hover", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1),
        position = { line = 10, character = 5 } } },
      { name = "definition", method = "textDocument/definition", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1),
        position = { line = 10, character = 5 } } },
      { name = "references", method = "textDocument/references", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1),
        position = { line = 10, character = 5 } } },
      { name = "rename", method = "textDocument/rename", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1),
        position = { line = 10, character = 5 }, newName = "newVarBench" } },
      { name = "formatting", method = "textDocument/formatting", params = {
        textDocument = vim.lsp.util.make_text_document_params(buf1) } },
    }
    for _, op in ipairs(ops) do
      local ok, e = pcall(function()
        local ms, result = measure_lsp_op(buf1, op.method, op.params)
        local count
        if op.name == "completion" and result and result.res then
          count = (result.res.items and #result.res.items) or (result.res and #result.res) or 0
        elseif op.name == "references" and result and result.res then
          count = #result.res
        end
        local count_str = count and string.format(" (%d)", count) or ""
        ctx:log(string.format("    %s: %.1fms%s", op.name, ms, count_str))
        ctx:record("lsp_operations", TS_CLIENT .. "/" .. op.name, { ms = ms, count = count })
      end)
      if not ok then ctx:log("    ERROR in " .. op.name .. ": " .. tostring(e)) end
    end

    -- 2c. Memory after operations
    local after_ops_snap = lib.snapshot()
    ctx:record("lifecycle_memory", TS_CLIENT .. "/after_ops", {
      nvim_rss_mb = math.floor(after_ops_snap.nvim_rss/1024/1024),
      lsp_rss_mb = math.floor(after_ops_snap.lsp_rss/1024/1024),
      grand_rss_mb = math.floor(after_ops_snap.grand_rss/1024/1024),
      cpu = after_ops_snap.cpu,
    })

    -- 2d. Stop ts_ls and verify cleanup
    ctx:log("\n--- 2d. Stop & Cleanup ---")
    local stop_start = lib.hrtime()
    stop_lsp(TS_CLIENT)
    local stop_ms = lib.elapsed_ms(stop_start)
    ctx:log(string.format("  Stop took: %dms", stop_ms))
    ctx:record("lifecycle_stop", TS_CLIENT, { stop_ms = stop_ms })

    local s_after_stop = collect_state("after_stop"); log_state(ctx, s_after_stop)

    local orphans, _ = check_orphans()
    if #orphans > 0 then
      ctx:log("  WARNING: Orphans detected after stop!")
      ctx:record("lifecycle_orphans", "after_stop", { count = #orphans })
      for _, o in ipairs(orphans) do
        ctx:log(string.format("    pid=%d rss=%d comm=%s", o.pid, o.rss or 0, o.comm or "?"))
      end
    else
      ctx:log("  No orphan processes after stop.")
    end

    -- 2e. Restart (second attach)
    ctx:log("\n--- 2e. Restart (Second Attach) ---")
    local attached2, attach2_ms, buf2 = start_lsp(ctx, proj_path, TS_CLIENT, 30000)
    if attached2 then
      ctx:log(string.format("  Second attach: %dms", attach2_ms))
      ctx:record("lifecycle_restart", TS_CLIENT, { attach_ms = attach2_ms })

      stop_lsp(TS_CLIENT)
      local s_after_restart = collect_state("after_restart_cleanup"); log_state(ctx, s_after_restart)
    end
  end

  -- =========================================================================
  -- 3. START/STOP CYCLING
  -- =========================================================================
  ctx:log("\n--- 3. Start/Stop Cycling (%d cycles) ---", math.min(switch_cycles, 15))
  local cycle_count = math.min(switch_cycles, 15)
  local cycle_attach_times = {}
  local cycle_memories = {}

  for i = 1, cycle_count do
    local attached_i, attach_i_ms, buf_i = start_lsp(ctx, proj_path, TS_CLIENT, 20000)
    if attached_i then
      table.insert(cycle_attach_times, attach_i_ms)
      local snap_i = lib.snapshot()
      table.insert(cycle_memories, {
        cycle = i, attach_ms = attach_i_ms,
        nvim_rss = snap_i.nvim_rss, lsp_rss = snap_i.lsp_rss,
      })
      stop_lsp(TS_CLIENT)
      vim.wait(500)
      if i % 5 == 0 then ctx:log(string.format("  Cycle %d/%d: attach=%dms", i, cycle_count, attach_i_ms)) end
    end
  end

  if #cycle_attach_times > 0 then
    local ca_stats = rm.stats(cycle_attach_times)
    ctx:record("lifecycle_cycling", TS_CLIENT, {
      cycles = #cycle_attach_times, avg_ms = ca_stats.avg,
      median_ms = ca_stats.median, min_ms = ca_stats.min,
      max_ms = ca_stats.max, p95_ms = ca_stats.p95,
    })
    ctx:log(string.format("  Cycle attach: avg=%.1fms median=%.0fms min=%.0fms max=%.0fms p95=%.0fms",
      ca_stats.avg, ca_stats.median, ca_stats.min, ca_stats.max, ca_stats.p95))

    -- Memory growth across cycles
    if #cycle_memories >= 3 then
      local first = cycle_memories[1]
      local last = cycle_memories[#cycle_memories]
      local nvim_growth = last.nvim_rss - first.nvim_rss
      local lsp_growth = last.lsp_rss - first.lsp_rss
      ctx:record("lifecycle_cycling_growth", TS_CLIENT, {
        cycles = #cycle_memories,
        nvim_growth_kb = math.floor(nvim_growth/1024),
        lsp_growth_kb = math.floor(lsp_growth/1024),
        nvim_growth_per_cycle_kb = math.floor(nvim_growth/1024/#cycle_memories),
        lsp_growth_per_cycle_kb = math.floor(lsp_growth/1024/#cycle_memories),
      })
      ctx:log(string.format("  Growth across %d cycles: nvim=%dKB lsp=%dKB",
        #cycle_memories, math.floor(nvim_growth/1024), math.floor(lsp_growth/1024)))
    end
  end

  local orphans_after_cycling, _ = check_orphans()
  if #orphans_after_cycling > 0 then
    ctx:log("  WARNING: Orphans after cycling!")
    ctx:record("lifecycle_orphans", "after_cycling", { count = #orphans_after_cycling })
  end

  -- =========================================================================
  -- 4. FILE OPEN/CLOSE CYCLES WITH LSP
  -- =========================================================================
  ctx:log("\n--- 4. File Open/Close Cycles (%d) ---", math.min(switch_cycles, 50))
  local proj_large = proj_dir .. "/large"

  -- Re-start LSP for file cycling
  local attached_fc = start_lsp(ctx, proj_path, TS_CLIENT, 20000)
  local s_before_fc = collect_state("before_file_cycles"); log_state(ctx, s_before_fc)

  local file_cycle_times = {}
  for i = 1, math.min(switch_cycles, 50) do
    local start = lib.hrtime()
    vim.cmd("e " .. proj_large .. "/src/file_" .. string.format("%04d.ts", (i % 1000) + 1))
    vim.bo.filetype = "typescript"
    vim.wait(200)
    vim.cmd("%bdelete!")
    vim.wait(100)
    table.insert(file_cycle_times, lib.elapsed_ms(start))
    if i % 10 == 0 then ctx:log(string.format("  File cycle %d/%d", i, math.min(switch_cycles, 50))) end
  end

  local fc_stats = rm.stats(file_cycle_times)
  ctx:record("engine_switching", "file_open_close", {
    cycles = #file_cycle_times, avg_ms = fc_stats.avg,
    median_ms = fc_stats.median, min_ms = fc_stats.min,
    max_ms = fc_stats.max, p95_ms = fc_stats.p95,
  })
  ctx:log(string.format("  File open/close: avg=%.1fms median=%.0fms p95=%.0fms",
    fc_stats.avg, fc_stats.median, fc_stats.p95))

  local s_after_fc = collect_state("after_file_cycles"); log_state(ctx, s_after_fc)
  stop_lsp(TS_CLIENT)

  -- =========================================================================
  -- 5. LOAD / WORST-CASE TESTING
  -- =========================================================================
  ctx:log("\n--- 5. Load & Worst-Case Testing ---")
  local s_before_load = collect_state("before_load_test"); log_state(ctx, s_before_load)

  -- 5a. Open many files simultaneously
  ctx:log("  Opening 50 files with LSP at once...")
  local open_times = {}
  local load_start = lib.hrtime()
  local many_bufs = {}

  local attached_load = start_lsp(ctx, proj_path, TS_CLIENT, 20000)
  if attached_load then
    local buf = open_ts_file(proj_path)
    for i = 1, 50 do
      local start = lib.hrtime()
      local b = vim.fn.bufadd(proj_large .. "/src/file_" .. string.format("%04d.ts", i))
      vim.fn.bufload(b)
      vim.bo[b].filetype = "typescript"
      table.insert(many_bufs, b)
      table.insert(open_times, lib.elapsed_ms(start))
    end
    local load_elapsed = lib.elapsed_ms(load_start)
    vim.wait(3000)

    local load_snap = lib.snapshot()
    local ac_total = lib.count_autocmds()
    ctx:log(string.format("  50 files opened in %dms", load_elapsed))
    ctx:log(string.format("  Load state: nvim=%dMB lsp=%dMB total=%dMB cpu=%.1f%% autocmds=%d",
      math.floor(load_snap.nvim_rss/1024/1024), math.floor(load_snap.lsp_rss/1024/1024),
      math.floor(load_snap.grand_rss/1024/1024), load_snap.cpu, ac_total))

    local load_stats = rm.stats(open_times)
    ctx:record("lifecycle_load_test", "50_files_bulk_open", {
      total_ms = load_elapsed, avg_ms = load_stats.avg, max_ms = load_stats.max,
      nvim_rss_mb = math.floor(load_snap.nvim_rss/1024/1024),
      lsp_rss_mb = math.floor(load_snap.lsp_rss/1024/1024),
      grand_rss_mb = math.floor(load_snap.grand_rss/1024/1024),
      cpu = load_snap.cpu, autocmds = ac_total,
    })

    -- 5b. Trigger heavy operations on all open files
    ctx:log("\n  Heavy operations across all buffers...")
    local heavy_ops = {}
    for _, b in ipairs(many_bufs) do
      local start = lib.hrtime()
      vim.lsp.buf_request(b, "textDocument/completion", {
        textDocument = vim.lsp.util.make_text_document_params(b),
        position = { line = 5, character = 3 },
        context = { triggerKind = 1 },
      }, function() end)
      table.insert(heavy_ops, lib.elapsed_ms(start))
      vim.wait(10)
    end
    vim.wait(3000)

    local heavy_snap = lib.snapshot()
    local h_stats = rm.stats(heavy_ops)
    ctx:log(string.format("  50 completion requests dispatched: avg=%.1fms max=%dms", h_stats.avg, h_stats.max))
    ctx:log(string.format("  Heavy load state: nvim=%dMB lsp=%dMB total=%dMB cpu=%.1f%%",
      math.floor(heavy_snap.nvim_rss/1024/1024), math.floor(heavy_snap.lsp_rss/1024/1024),
      math.floor(heavy_snap.grand_rss/1024/1024), heavy_snap.cpu))

    ctx:record("lifecycle_load_test", "50_completion_burst", {
      avg_ms = h_stats.avg, max_ms = h_stats.max,
      nvim_rss_mb = math.floor(heavy_snap.nvim_rss/1024/1024),
      lsp_rss_mb = math.floor(heavy_snap.lsp_rss/1024/1024),
      grand_rss_mb = math.floor(heavy_snap.grand_rss/1024/1024),
      cpu = heavy_snap.cpu,
    })

    -- 5c. Measure diagnostic count
    local diag_count = #vim.diagnostic.get()
    ctx:log(string.format("  Total diagnostics across all buffers: %d", diag_count))
    ctx:record("lifecycle_load_test", "diagnostics_count", { count = diag_count })

    -- Clean up: close all extra buffers
    for _, b in ipairs(many_bufs) do
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
    vim.wait(2000)
  end

  local s_after_load = collect_state("after_load_test"); log_state(ctx, s_after_load)
  stop_lsp(TS_CLIENT)

  local s_after_load_cleanup = collect_state("after_load_cleanup"); log_state(ctx, s_after_load_cleanup)

  -- =========================================================================
  -- 6. CROSS-ENGINE SUBCESS VERIFICATION (typescript-tools in subprocess)
  -- =========================================================================
  ctx:log("\n--- 6. Cross-Engine Verification (%s) ---", ALT_CLIENT)
  ctx:log("  Launching subprocess for typescript-tools...")

  local engines_mod = require("managers.language_engine")
  local original_engine = engines_mod.get("typescript")

  -- Save original dat, set typescript-tools, launch subprocess
  local dat_path = vim.fn.stdpath("config") .. "/language_engines.dat"
  local dat_backup
  local f = io.open(dat_path, "r")
  if f then dat_backup = f:read("*a"); f:close() end

  local original_eng = "ts_ls"
  if dat_backup then
    local lang, eng = dat_backup:match("^(%S+)%s+(%S+)$")
    if lang and eng then original_eng = eng end
  end

  engines_mod.set("typescript", "typescript_tools")

  local nvim_bin = vim.env.NVIM or "nvim"
  local cwd = vim.fn.getcwd()
  local alt_output = "/tmp/ts_bench_typescript_tools_cross.json"
  local measure_script = cwd .. "/bench/scripts/engine_measure.lua"

  local env = string.format("ENGINE_NAME=%s PROJ_PATH=%s PROJ_LABEL=%s OUTPUT_FILE=%s",
    "typescript-tools", proj_path, "cross", alt_output)
  local alt_cmd = string.format('%s %s --headless -c "luafile %s" -c "qa!"',
    env, nvim_bin, measure_script)
  os.execute(alt_cmd)

  -- Restore original engine
  if dat_backup then
    local f2 = io.open(dat_path, "w")
    if f2 then f2:write(dat_backup); f2:close() end
  end

  -- Parse subprocess results
  local alt_f = io.open(alt_output, "r")
  if alt_f then
    local alt_content = alt_f:read("*a")
    alt_f:close()
    os.remove(alt_output)
    local ok, alt_data = pcall(vim.json.decode, alt_content)
    if ok then
      if alt_data.attached then
        ctx:log(string.format("  typescript-tools: attached (%dms)", alt_data.attach_ms))
        ctx:log(string.format("    memory: nvim=%dMB lsp=%dMB total=%dMB cpu=%.1f%%",
          alt_data.memory.baseline.nvim_rss_mb, alt_data.memory.baseline.lsp_rss_mb,
          alt_data.memory.baseline.grand_rss_mb, alt_data.cpu.baseline or 0))
        if alt_data.operations then
          for op, op_data in pairs(alt_data.operations) do
            local ms = type(op_data) == "table" and op_data.ms or op_data
            ctx:log(string.format("    %s: %.1fms", op, ms))
          end
        end
        ctx:record("cross_engine", "typescript-tools", {
          attached = true, attach_ms = alt_data.attach_ms,
          nvim_rss_mb = alt_data.memory.baseline.nvim_rss_mb,
          lsp_rss_mb = alt_data.memory.baseline.lsp_rss_mb,
          grand_rss_mb = alt_data.memory.baseline.grand_rss_mb,
        })
      else
        ctx:log("  typescript-tools: NOT AVAILABLE in subprocess")
        ctx:record("cross_engine", "typescript-tools", { attached = false })
      end
    end
  else
    ctx:log("  typescript-tools: subprocess failed to produce output")
    ctx:record("cross_engine", "typescript-tools", { attached = false, error = "no output" })
  end

  -- Restore original engine in memory too
  if original_eng then
    engines_mod.set("typescript", original_eng)
  end

  -- =========================================================================
  -- 7. FINAL ORPHAN DETECTION & MEMORY GROWTH
  -- =========================================================================
  ctx:log("\n--- 7. Final Orphan Detection ---")
  local final_orphans, all_procs = check_orphans()
  ctx:record("lifecycle_orphans", "final_detection", {
    total_children = #all_procs, orphans = #final_orphans, zombie_count = #final_orphans,
  })
  if #final_orphans > 0 then
    ctx:log(string.format("  WARNING: %d orphan/zombie processes detected!", #final_orphans))
    for _, p in ipairs(final_orphans) do
      ctx:log(string.format("    pid=%d rss=%d comm=%s", p.pid, p.rss or 0, p.comm or "?"))
    end
  else
    ctx:log("  No orphan processes detected.")
  end

  ctx:log("\n--- 8. Final Memory Growth Analysis ---")
  local mem_samples = {}
  collectgarbage("collect")
  for i = 1, 5 do
    collectgarbage("collect")
    local rss_kb = lib.nvim_rss_kb()
    local gc_kb = collectgarbage("count")
    table.insert(mem_samples, { rss_kb = rss_kb, gc_kb = gc_kb })
    vim.wait(200)
  end

  if #mem_samples >= 2 then
    local first_mem = mem_samples[1]
    local last_mem = mem_samples[#mem_samples]
    local growth_kb = last_mem.rss_kb - first_mem.rss_kb
    local growth_pct = first_mem.rss_kb > 0 and (growth_kb / first_mem.rss_kb) * 100 or 0
    ctx:record("lifecycle_memory", "growth_analysis", {
      initial_rss_kb = first_mem.rss_kb, final_rss_kb = last_mem.rss_kb,
      growth_kb = growth_kb, growth_percent = math.floor(growth_pct * 100) / 100,
      initial_gc_kb = first_mem.gc_kb, final_gc_kb = last_mem.gc_kb,
      samples = #mem_samples,
    })
    ctx:log(string.format("  Memory: initial=%dKB final=%dKB growth=%dKB (%.1f%%)",
      first_mem.rss_kb, last_mem.rss_kb, growth_kb, growth_pct))
    if growth_pct > 10 then
      ctx:log("  WARNING: Possible memory leak (>10% growth)")
    end
  end

  return ctx:finalize()
end

return M
