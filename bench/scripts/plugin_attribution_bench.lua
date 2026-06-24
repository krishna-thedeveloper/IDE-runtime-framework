local rm = dofile(vim.fn.getcwd() .. "/bench/scripts/result_manager.lua")

local M = {}

local KNOWN_PLUGINS = {
  ["blink.cmp"] = "blink%.cmp",
  ["cmp"] = "cmp",
  ["snacks"] = "snacks",
  ["treesitter"] = "treesitter",
  ["nvim-treesitter"] = "nvim%-treesitter",
  ["lspconfig"] = "lspconfig",
  ["mason"] = "mason",
  ["mason-lspconfig"] = "mason%-lspconfig",
  ["which-key"] = "which%-key",
  ["gitsigns"] = "gitsigns",
  ["telescope"] = "telescope",
  ["fzf-lua"] = "fzf%-lua",
  ["oil"] = "oil",
  ["neo-tree"] = "neo%-tree",
  ["nvim-cmp"] = "nvim%-cmp",
  ["indent-blankline"] = "indent%-blankline",
  ["lualine"] = "lualine",
  ["bufferline"] = "bufferline",
  ["alpha"] = "alpha",
  ["dashboard"] = "dashboard",
  ["tokyonight"] = "tokyonight",
  ["catppuccin"] = "catppuccin",
  ["kanagawa"] = "kanagawa",
  ["everforest"] = "everforest",
  ["gruvbox"] = "gruvbox",
  ["onedark"] = "onedark",
  ["noice"] = "noice",
  ["notify"] = "notify",
  ["mini"] = "mini%.",
  ["todo-comments"] = "todo%-comments",
  ["comment"] = "comment%.",
  ["autopairs"] = "autopairs",
  ["copilot"] = "copilot",
  ["trouble"] = "trouble",
  ["symbols-outline"] = "symbols%-outline",
  ["nvim-dap"] = "nvim%-dap",
  ["neotest"] = "neotest",
  ["conform"] = "conform",
  ["none-ls"] = "none%-ls",
  ["null-ls"] = "null%-ls",
}

function M.run(opts)
  opts = opts or {}
  local cold_n = opts.cold or 10
  local nvim_bin = "nvim"

  local ctx = rm.create_run({ benchmark = "plugin_attribution", cold = cold_n })
  ctx:open_log("plugin_attribution")

  ctx:log("=== Plugin Load Attribution Benchmark ===")
  ctx:log("Maps --startuptime entries to known plugins\n")

  local tmp_log = rm.bench_dir .. "/attribution_tmp.log"

  local function parse_attribution()
    local entries = {}
    local sf = io.open(tmp_log, "r")
    if not sf then return entries end
    for line in sf:lines() do
      local ms, event = line:match("^%s*(%d+%.?%d*)%s+(.+)$")
      if ms and event then
        table.insert(entries, { ms = tonumber(ms), event = event })
      end
    end
    sf:close()
    return entries
  end

  local function classify_entries(entries)
    local plugin_times = {}
    local other_times = 0
    local total_ms = 0

    for _, e in ipairs(entries) do
      total_ms = math.max(total_ms, e.ms)
    end

    for _, e in ipairs(entries) do
      local matched = false
      for plugin, pattern in pairs(KNOWN_PLUGINS) do
        if e.event:match(pattern) then
          plugin_times[plugin] = (plugin_times[plugin] or 0) + e.ms
          matched = true
          break
        end
      end
      if not matched then
        if e.event:match("^loading ") then
          local name = e.event:match("^loading (.+)")
          if name then
            plugin_times[name] = (plugin_times[name] or 0) + e.ms
          else
            other_times = other_times + e.ms
          end
        else
          other_times = other_times + e.ms
        end
      end
    end

    return plugin_times, other_times, total_ms
  end

  local function run_single()
    local args = { nvim_bin, "--headless", "--startuptime", tmp_log, "-c", "qa!" }
    local handle = io.popen(table.concat(args, " ") .. " 2>&1")
    handle:read("*a")
    handle:close()

    local entries = parse_attribution()
    local plugin_times, other_ms, total_ms = classify_entries(entries)
    os.execute("rm -f " .. tmp_log)

    return plugin_times, other_ms, total_ms, entries
  end

  local all_attributions = {}

  for i = 1, cold_n do
    ctx:log(string.format("Run %d/%d...", i, cold_n))
    local plugin_times, other_ms, total_ms = run_single()
    table.insert(all_attributions, { plugins = plugin_times, other = other_ms, total = total_ms })

    for plugin, ms in pairs(plugin_times) do
      local pct = (ms / math.max(total_ms, 1)) * 100
      ctx:record("plugin_load", string.format("run_%d", i), {
        plugin = plugin,
        ms = math.floor(ms * 100) / 100,
        pct = math.floor(pct * 100) / 100,
        total_ms = math.floor(total_ms * 100) / 100,
      })
    end
    ctx:record("plugin_load", string.format("run_%d", i), {
      plugin = "(other)",
      ms = math.floor(other_ms * 100) / 100,
      pct = math.floor((other_ms / math.max(total_ms, 1)) * 10000) / 100,
      total_ms = math.floor(total_ms * 100) / 100,
    })
  end

  local combined = {}
  for _, run_data in ipairs(all_attributions) do
    for plugin, ms in pairs(run_data.plugins) do
      combined[plugin] = (combined[plugin] or 0) + ms
    end
    combined["(other)"] = (combined["(other)"] or 0) + run_data.other
  end

  local sorted = {}
  for k, v in pairs(combined) do sorted[#sorted+1] = { name = k, total = v } end
  table.sort(sorted, function(a, b) return a.total > b.total end)

  local avg_total = 0
  for _, run_data in ipairs(all_attributions) do
    avg_total = avg_total + run_data.total
  end
  avg_total = avg_total / #all_attributions

  ctx:log("\n=== Plugin Load Attribution (averaged over " .. cold_n .. " runs) ===")
  ctx:log(string.format("%-30s %10s %8s", "Plugin", "ms", "% Startup"))
  ctx:log(string.rep("-", 50))
  for _, s in ipairs(sorted) do
    local avg_ms = s.total / cold_n
    local pct = (avg_ms / math.max(avg_total, 1)) * 100
    ctx:record("plugin_attribution_stats", s.name, {
      avg_ms = math.floor(avg_ms * 100) / 100,
      pct = math.floor(pct * 100) / 100,
      total_ms_across_runs = math.floor(s.total * 100) / 100,
    })
    ctx:log(string.format("%-30s %8.2f %7.1f%%", s.name, avg_ms, pct))
  end

  ctx:log(string.format("\nAverage total startup time: %.2f ms", avg_total))

  local final = ctx:finalize()
  return final
end

return M
