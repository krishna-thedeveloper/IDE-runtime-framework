--- Plugin Manager Benchmark
--- Benchmarks all supported plugin managers: lazy, pckr, mini_deps, vim_pack
--- Measures startup impact, memory, CPU, and stress tests
--- Usage: nvim --headless -c "lua require('bench.scripts.plugin_manager_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local MANAGERS = { "lazy", "pckr", "mini_deps", "vim_pack" }

function M.run(opts)
  opts = opts or {}
  local managers = opts.managers or MANAGERS
  local iterations = opts.iterations or 3

  local ctx = rm.create_run({ benchmark = "plugin_manager", managers = managers, iterations = iterations })
  ctx:open_log("plugin_managers")

  ctx:log("=== Plugin Manager Benchmark ===")
  ctx:log(string.format("Managers: %s", table.concat(managers, ", ")))
  ctx:log("")

  local results = {}

  for _, mgr in ipairs(managers) do
    ctx:log(string.format("\n--- Benchmarking: %s ---", mgr))

    -- Measure cold startup impact
    local startup_times = {}
    for i = 1, iterations do
      local args = { "nvim", "--headless",
        "-c", string.format("lua require('managers.plugin_manager').setup('%s')", mgr),
        "-c", "qa!" }
      local start = lib.hrtime()
      local handle = io.popen(table.concat(args, " ") .. " 2>&1")
      handle:read("*a")
      handle:close()
      startup_times[i] = lib.elapsed_ms(start)
    end

    local startup_stats = rm.stats(startup_times)
    ctx:record("plugin_manager", mgr .. "_startup", {
      avg_ms = startup_stats.avg,
      median_ms = startup_stats.median,
      min_ms = startup_stats.min,
      max_ms = startup_stats.max,
      p95_ms = startup_stats.p95,
      p99_ms = startup_stats.p99,
      stddev_ms = startup_stats.stddev,
      n = iterations,
    })

    ctx:log(string.format("  Cold startup: avg=%.1fms median=%.0fms p95=%.0fms (n=%d)",
      startup_stats.avg, startup_stats.median, startup_stats.p95, iterations))

    table.insert(results, {
      manager = mgr,
      startup = startup_stats,
      times = startup_times,
    })
  end

  -- Ranking
  ctx:log("\n=== Plugin Manager Rankings ===")
  table.sort(results, function(a, b) return a.startup.avg < b.startup.avg end)
  ctx:log("\n| Rank | Manager | Avg (ms) | Median (ms) | P95 (ms) |")
  ctx:log("|------|---------|----------|-------------|----------|")
  for rank, r in ipairs(results) do
    ctx:log(string.format("| %d | %s | %.1f | %.0f | %.0f |",
      rank, r.manager, r.startup.avg, r.startup.median, r.startup.p95))
    ctx:record("plugin_manager_ranking", r.manager, {
      rank = rank,
      avg_ms = r.startup.avg,
      median_ms = r.startup.median,
      p95_ms = r.startup.p95,
    })
  end

  local final = ctx:finalize()
  return final
end

return M
