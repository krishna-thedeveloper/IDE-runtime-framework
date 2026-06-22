# Profiling

## Lazy.nvim Profiler

### Profile Startup

```vim
:Lazy profile
```

This shows each plugin's load time and total startup time.

### Profile with Details

```vim
:Lazy profile --local     " Only local plugins
:Lazy profile --startup   " Detailed startup breakdown
```

### Reading the Profile

The profile output shows:

| Column | Meaning |
|---|---|
| Plugin | Plugin name |
| Time | Time spent loading this plugin |
| % | Percentage of total startup time |
| Trigger | What caused the plugin to load (event, key, command, etc.) |

## Manual Profiling

### Measure Require Time

```lua
:lua local start = vim.fn.reltime(); require("plugin"); print(vim.fn.reltimestr(vim.fn.reltime(start)))
```

### Measure Function Execution

```lua
local start = vim.uv.hrtime()
-- code to measure
local elapsed = (vim.uv.hrtime() - start) / 1e6
print(string.format("Took %.2f ms", elapsed))
```

### Track Plugin Load Order

```vim
:lua for _, plugin in ipairs(require("lazy.core.config").spec.plugins) do print(plugin.name, plugin._.loaded and "loaded" or "lazy") end
```

## Startup Optimization Targets

Based on the architecture, the heaviest potential contributors to startup time are:

1. **nvim-treesitter** (non-lazy) — parsers and highlighting setup.
2. **Colorscheme** (non-lazy only for the active theme) — highlight group generation.
3. **Lazy.nvim itself** — spec processing, module discovery.

Everything else is deferred to `VeryLazy` or later.

## Benchmark Methodology

To measure startup time:

```bash
# Cold startup (no cache)
nvim --headless +qa 2>&1 | rg "startup"
```

```bash
# With profiling
nvim --headless "+Lazy! profile" +qa
```

```vim
:echo vim.v.profiling_file   " If profiling enabled
```

## Interpreting Results

- Startup under **100ms** is excellent.
- Startup under **200ms** is good.
- Startup over **300ms** indicates something loading eagerly that shouldn't be.

If startup is slow:

1. Run `:Lazy profile` to identify the slowest plugins.
2. Check if they can be lazy-loaded (appropriate trigger).
3. Check if their spec has `lazy = false` unnecessarily.
4. Consider alternatives or lighter configurations.

---

**Previous:** [Debugging](debugging.md)
