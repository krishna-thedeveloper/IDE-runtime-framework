# Benchmark Framework Guide

## Overview

This is a production-grade benchmarking framework for measuring Neovim plugin/runtime performance. It produces versioned, timestamped results with raw logs, CSV, JSON, Markdown reports, and automated regression detection.

## Directory Structure

```
bench/
├── scripts/                    # Benchmark runner scripts
│   ├── result_manager.lua      # Core result storage, versioning, statistics
│   ├── startup_bench.lua       # Cold/warm/hot startup with statistical analysis
│   ├── lsp_bench.lua           # LSP attach, operations, scaling, multi-LSP
│   ├── completion_bench.lua    # Completion latency, memory, stress tests
│   ├── theme_bench.lua         # Theme startup impact, switching, memory
│   ├── buffer_bench.lua        # Buffer/window scaling, treesitter, pickers
│   ├── engine_switching_bench.lua  # Theme/LSP switching, lifecycle cleanup
│   ├── stability_bench.lua     # Idle tests, GC pressure, failure recovery
│   ├── plugin_manager_bench.lua # All 4 managers: startup, ranking
│   ├── report_generator.lua    # Executive summary, comprehensive reports
│   ├── comparison_engine.lua   # Regression detection, historical comparison
│   └── dashboard_generator.lua # ASCII trend charts, JSON export
├── runner.lua                  # Orchestrator: runs benchmarks in sequence
├── seed.lua                    # Test project generator (10-10000 files)
├── lib.lua                     # Shared benchmark library (timing, memory, LSP ops)
├── projects/                   # Generated test fixtures (gitignored)
├── results/
│   ├── historical/             # Versioned run directories (YYYY-MM-DD_HH-MM-SS)
│   │   └── <timestamp>/
│   │       ├── raw/            # Raw logs, CSV, JSON
│   │       └── reports/        # Markdown reports
│   ├── reports/                # Aggregated reports
│   ├── comparisons/            # Comparison & regression reports
│   └── raw/                    # Legacy raw outputs
├── dashboards/                 # Dashboard JSON data for visualization
└── docs/
    └── benchmark-guide.md      # This file
```

## Quick Start

Run the full benchmark suite:
```bash
make bench-all
```

Run a quick overview (~10 minutes):
```bash
make bench-fast
```

Run specific benchmarks:
```bash
make bench-startup      # Startup only
make bench-lsp          # LSP only
make bench-completion   # Completion only
make bench-theme        # Theme only
make bench-stability    # Stability/idle test
```

## Benchmark Categories

### 1. Startup (bench/scripts/startup_bench.lua)
- Measures cold/warm/hot startup times
- Collects wall clock, startuptime, median, p95, p99, stddev, variance
- Parses `--startuptime` output for granular loading analysis
- Configurable iterations (cold=25, warm=10, hot=10 by default)

### 2. LSP (bench/scripts/lsp_bench.lua)
- Per-server: attach time, diagnostics, completion, hover, definition, references, rename, code actions, formatting
- Project scaling: small (10 files) through huge (10000 files)
- Multi-LSP: simultaneous TypeScript + Lua + JSON
- Duplicate client detection

### 3. Completion (bench/scripts/completion_bench.lua)
- Latency across small/medium/large files
- Memory baseline vs. active typing
- Multiple samples per measurement

### 4. Theme (bench/scripts/theme_bench.lua)
- Startup impact per theme (7 themes, 5 samples each)
- Theme switching latency
- Memory delta on theme load

### 5. Buffer/Window (bench/scripts/buffer_bench.lua)
- Buffer scaling: 1, 10, 50, 100, 500, 1000 buffers
- Window scaling: 1, 2, 4, 8, 16 windows
- Treesitter parse times
- Picker startup benchmark

### 6. Engine Switching (bench/scripts/engine_switching_bench.lua)
- Theme switching cycles (up to 500)
- LSP engine switching (ts_ls <-> typescript_tools)
- File open/close cycles
- Orphan/zombie process detection
- Memory leak analysis

### 7. Stability (bench/scripts/stability_bench.lua)
- Idle tests with periodic snapshots
- Memory growth tracking
- Autocmd/timer leak detection
- GC pressure test
- LSP crash recovery simulation
- Resource cleanup verification

### 8. Plugin Manager (bench/scripts/plugin_manager_bench.lua)
- Benchmarks lazy, pckr, mini_deps, vim_pack
- Cold startup metrics
- Ranking report

## Usage

### Running a specific benchmark with custom parameters:

```bash
# Custom startup iterations
nvim --headless -c "lua dofile('bench/scripts/startup_bench.lua').run({cold=25, warm=10, hot=10})" -c "qa!"

# Custom switching cycles
nvim --headless -c "lua dofile('bench/scripts/engine_switching_bench.lua').run({cycles=500})" -c "qa!"

# Custom idle duration
nvim --headless -c "lua dofile('bench/scripts/stability_bench.lua').run({idle_minutes=15})" -c "qa!"
```

### Running the full orchestrator:
```bash
# Run all benchmarks
nvim --headless -c "lua dofile('bench/runner.lua')" -c "qa!"

# Run specific benchmarks
nvim --headless -c "lua arg={'startup','lsp'}; dofile('bench/runner.lua')" -c "qa!"
```

## Result Storage

Every benchmark run creates a versioned directory:
```
bench/results/historical/2026-01-15_14-30-00/
├── raw/
│   ├── startup_ts_ls.log
│   ├── all_results.json        # Complete result data
│   ├── startup_stats.csv       # Per-category CSV
│   ├── lsp_operation.csv
│   └── ...
└── reports/
    └── benchmark-report.md     # Generated report
```

## Reports

Generate reports from historical data:
```bash
make bench-report
```

Reports include:
- **Executive Summary**: KPI dashboard, health score, warnings
- **Comprehensive Report**: All metrics across all runs
- **Startup Report**: Cold/warm/hot statistics with full distribution

## Comparison & Regression Detection

```bash
make bench-compare
```

Compares the latest two runs and flags regressions at thresholds:
- **1%**: Slight change
- **5%**: Minor regression
- **10%**: Warning
- **20%**: Critical regression

Reports highlight degrading, improving, and stable metrics with historical trends.

## Dashboards

```bash
make bench-dashboard
```

Generates ASCII trend charts and JSON data for:
- Startup latency trends
- Memory usage trends
- LSP attach time trends
- Completion latency trends

JSON output can be used with external visualization tools (Grafana, etc.).

## Historical Data Management

List all historical runs:
```bash
make bench-list
```

View storage usage:
```bash
make bench-stats
```

Clean generated data (projects + results):
```bash
make bench-clean
```

## Architecture

### Data Flow
```
Seed Projects → Run Benchmarks → Store Raw Results → Generate Reports → Compare → Dashboard
     │               │                  │                   │              │          │
     ▼               ▼                  ▼                   ▼              ▼          ▼
  bench/        benchmark           historical/         reports/      comparisons/  dashboards/
  projects/     scripts/              YYYY-MM-DD/
```

### Result Manager (bench/scripts/result_manager.lua)
Central component that all benchmarks use for:
- Creating versioned run directories
- Recording metrics with category/name tagging
- Writing CSV, JSON, and log outputs
- Computing statistics (mean, median, p95, p99, stddev)
- Loading historical data for comparison

### Statistics
All numeric metrics include:
- `avg`, `min`, `max` — Basic statistics
- `median`, `p95`, `p99` — Percentile distribution
- `stddev`, `variance` — Dispersion metrics
- `sorted` — Full sorted array for custom analysis

## Extending

### Adding a new benchmark:
1. Create `bench/scripts/your_bench.lua`
2. Use the result manager:
   ```lua
   local rm = require('bench.scripts.result_manager')
   local ctx = rm.create_run({ benchmark = "your_category" })
   ctx:open_log("your_benchmark")
   ctx:record("category", "name", { metric1 = value1, metric2 = value2 })
   local final = ctx:finalize()
   ```
3. Add target to Makefile
4. Add to `bench/runner.lua`

### Adding a new metric to existing benchmarks:
Simply add a new `ctx:record()` call within the benchmark script.

## Key Design Decisions

1. **No data deletion**: Historical runs are never deleted or overwritten
2. **Versioned storage**: Every run gets a unique timestamped directory
3. **Multiple output formats**: Logs, CSV (per category), JSON (complete), Markdown (reports)
4. **Statistical rigor**: Multiple samples per measurement, percentile reporting
5. **Traceability**: Every result links back to its raw data file
6. **Regression detection**: Automated comparison with configurable thresholds
7. **Reproducibility**: All project fixtures are generated by seed scripts
