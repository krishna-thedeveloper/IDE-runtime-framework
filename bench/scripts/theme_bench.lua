--- Theme Benchmark
--- Measures startup impact, memory, redraw speed, and switching latency
--- Usage: nvim --headless -c "lua require('bench.scripts.theme_bench').run()" -c "qa!"

local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")
local lib = dofile(vim.fn.getcwd() .. "/bench/lib.lua")

local M = {}

local THEME_MAP = {
  catppuccin   = "catppuccin",
  tokyonight   = "tokyonight",
  kanagawa     = "kanagawa",
  everforest   = "everforest",
  onedark      = "onedark",
  ["gruvbox-material"] = "gruvbox-material",
  github       = "github_dark",
}

function M.run(opts)
  opts = opts or {}
  local ctx = rm.create_run({ benchmark = "themes" })
  ctx:open_log("themes")

  ctx:log("=== Theme Benchmark ===")
  ctx:log("")

  local available = {}
  for theme_name, cs_name in pairs(THEME_MAP) do
    local ok = pcall(vim.cmd, "colorscheme " .. cs_name)
    if ok then
      table.insert(available, { name = theme_name, colorscheme = cs_name })
    end
    pcall(vim.cmd, "colorscheme catppuccin")
  end
  vim.wait(500)

  ctx:log(string.format("Available themes: %d", #available))
  for _, th in ipairs(available) do
    ctx:log(string.format("  %s -> %s", th.name, th.colorscheme))
  end

  -- Theme switching latency
  ctx:log("\n--- Theme Switching ---")
  if #available == 0 then
    ctx:log("  No themes available")
  else
    vim.cmd("colorscheme " .. available[1].colorscheme)
    local current = available[1].name
    for _, th in ipairs(available) do
      if th.name ~= current then
        local switch_times = {}
        for i = 1, 5 do
          local start = lib.hrtime()
          vim.cmd("colorscheme " .. th.colorscheme)
          switch_times[i] = lib.elapsed_ms(start)
          vim.wait(100)
        end
        local stats = rm.stats(switch_times)
        ctx:record("theme_switching", current .. "->" .. th.name, {
          avg_ms = stats.avg,
          median_ms = stats.median,
          min_ms = stats.min,
          max_ms = stats.max,
        })
        ctx:log(string.format("  %s -> %s: avg=%.1fms p95=%.0fms", current, th.name, stats.avg, stats.p95))
        current = th.name
      end
    end
  end

  -- Memory impact per theme
  ctx:log("\n--- Memory Impact ---")
  if #available > 0 then
    for _, th in ipairs(available) do
      collectgarbage("collect")
      local before = lib.nvim_rss_kb()
      vim.cmd("colorscheme " .. th.colorscheme)
      vim.wait(200)
      collectgarbage("collect")
      local after = lib.nvim_rss_kb()
      ctx:record("theme_memory", th.name, {
        baseline_kb = before,
        after_kb = after,
        delta_kb = after - before,
      })
      ctx:log(string.format("  %s: %+d KB", th.name, after - before))
    end
  end

  -- Redraw speed test (approximate)
  ctx:log("\n--- Redraw Speed ---")
  if #available > 0 then
    for _, th in ipairs(available) do
      vim.cmd("colorscheme " .. th.colorscheme)
      collectgarbage("collect")
      local redraw_times = {}
      for i = 1, 10 do
        local start = lib.hrtime()
        vim.cmd("redraw!")
        redraw_times[i] = lib.elapsed_ms(start)
      end
      local stats = rm.stats(redraw_times)
      ctx:record("theme_redraw", th.name, {
        avg_ms = stats.avg,
        median_ms = stats.median,
        max_ms = stats.max,
      })
      ctx:log(string.format("  %s: redraw avg=%.1fms", th.name, stats.avg))
    end
  end

  local final = ctx:finalize()
  return final
end

return M
