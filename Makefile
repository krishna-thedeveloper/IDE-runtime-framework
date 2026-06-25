# Benchmark Makefile — run from project root (nvim/)
# Usage:
#   make bench-all           # Run ALL benchmarks (takes ~60 min)
#   make bench-fast          # Quick run (startup + lsp, ~10 min)
#   make bench-startup       # Startup benchmark only
#   make bench-lsp           # LSP benchmark only
#   make bench-full          # Full benchmark suite (~90 min)
#   make bench-compare       # Compare last two runs and detect regressions
#   make bench-report        # Generate all reports from historical data
#   make bench-dashboard     # Generate dashboard with trend charts
#   make bench-seed          # Generate test projects only
#   make bench-clean         # Remove all generated data
#   make bench-list          # List all historical benchmark results
#
# Advanced:
#   BENCH_ENGINE=ts_ls make bench-startup    # Run with specific engine
#   BENCH_COLD=25 make bench-startup         # Custom iterations
#   make bench-run BM="startup lsp"          # Run specific benchmarks

BENCH_DIR = $(CURDIR)/bench

# Default engine
BENCH_ENGINE ?= ts_ls
BM ?=

# ──────────────────────────────────────────────────────────────────────────────
# Target groups
# ──────────────────────────────────────────────────────────────────────────────

.PHONY: bench-all bench-full bench-fast bench-seed bench-startup bench-lsp \
        bench-completion bench-theme bench-buffer bench-switching bench-stability \
        bench-plugin-manager bench-plugin-attribution bench-cpu bench-ts-backend \
        bench-treesitter bench-project-indexing bench-git bench-editing bench-search \
        bench-run bench-report bench-compare bench-dashboard \
        bench-clean bench-list bench-comprehensive

# Run ALL benchmarks (comprehensive, ~60-90 min)
bench-all:
	RUN_TIMESTAMP=$$(date +%Y-%m-%d_%H-%M-%S) $(MAKE) bench-seed bench-comprehensive bench-report bench-compare bench-dashboard
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           ALL BENCHMARKS COMPLETE                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	@echo "Results: $(BENCH_DIR)/results/historical/"
	@echo "Reports: $(BENCH_DIR)/results/reports/"
	@ls -lt $(BENCH_DIR)/results/historical/ | head -5

# New benchmarks (Tier 1-3 additions)
bench-new: bench-plugin-attribution bench-cpu bench-ts-backend bench-treesitter bench-project-indexing bench-git bench-editing bench-search

# Full benchmark suite (all measurement benchmarks)
bench-comprehensive: bench-startup bench-lsp bench-completion bench-theme bench-buffer bench-switching bench-stability bench-new

# Fast benchmark (quick overview, ~10 min)
bench-fast: bench-seed
	@echo "=== Fast Benchmark (startup + LSP) ==="
	nvim --headless -c "lua dofile('$(BENCH_DIR)/runner.lua')" -c "qa!" 2>&1 | tail -40

# ──────────────────────────────────────────────────────────────────────────────
# Individual benchmarks
# ──────────────────────────────────────────────────────────────────────────────

bench-seed:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Generating benchmark projects                 ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "luafile $(BENCH_DIR)/seed.lua" -c "qa!" 2>&1
	@echo "Projects generated in $(BENCH_DIR)/projects/"
	@echo ""

bench-startup: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Startup Benchmark                             ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/startup_bench.lua').run({engine='$(BENCH_ENGINE)', cold=10, warm=5, hot=5})" -c "qa!" 2>&1
	@echo ""

bench-lsp: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           LSP Benchmark                                 ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/lsp_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-completion: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Completion Benchmark                          ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/completion_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-theme: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Theme Benchmark                               ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/theme_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-buffer: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Buffer/Window Benchmark                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/buffer_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-switching: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Engine Switching & Lifecycle                  ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/engine_switching_bench.lua').run({cycles=100})" -c "qa!" 2>&1
	@echo ""

bench-stability: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Stability & Idle Test                         ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/stability_bench.lua').run({idle_minutes=5})" -c "qa!" 2>&1
	@echo ""

bench-plugin-manager:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Plugin Manager Benchmark                      ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/plugin_manager_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-plugin-attribution: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Plugin Load Attribution                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/plugin_attribution_bench.lua').run({cold=5})" -c "qa!" 2>&1
	@echo ""

bench-cpu: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           CPU Profiling Benchmark                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/cpu_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-ts-backend: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           TS Backend Comparison: ts_ls vs typescript-tools ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/ts_backend_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-treesitter: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Treesitter Benchmark                          ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/treesitter_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-project-indexing: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Project Indexing Benchmark                    ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/project_indexing_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-git:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Git Benchmark                                 ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/git_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-editing:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Editing Workflow Benchmark                    ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/editing_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

bench-search:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Search/Picker Benchmark                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/search_bench.lua').run()" -c "qa!" 2>&1
	@echo ""

# Run specific benchmarks (set BM="startup lsp completion")
bench-run: bench-seed
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Custom Benchmark: $(BM)                       ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua arg={$(BM)}; dofile('$(BENCH_DIR)/runner.lua')" -c "qa!" 2>&1
	@echo ""

# ──────────────────────────────────────────────────────────────────────────────
# Reports, comparisons, dashboards
# ──────────────────────────────────────────────────────────────────────────────

bench-report:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Generating Reports                            ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/report_generator.lua').generate_all()" -c "qa!" 2>&1
	@echo "Reports in $(BENCH_DIR)/results/reports/"

bench-compare:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Running Comparison & Regression Detection     ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/comparison_engine.lua').run()" -c "qa!" 2>&1
	@echo "Comparisons in $(BENCH_DIR)/results/comparisons/"

bench-dashboard:
	@echo "╔══════════════════════════════════════════════════════════╗"
	@echo "║           Generating Dashboards                         ║"
	@echo "╚══════════════════════════════════════════════════════════╝"
	nvim --headless -c "lua dofile('$(BENCH_DIR)/scripts/dashboard_generator.lua').run()" -c "qa!" 2>&1
	@echo "Dashboards in $(BENCH_DIR)/results/reports/ and $(BENCH_DIR)/dashboards/"

# ──────────────────────────────────────────────────────────────────────────────
# Utility
# ──────────────────────────────────────────────────────────────────────────────

bench-list:
	@echo "Historical benchmark runs:"
	@echo "--------------------------"
	@if ls -d $(BENCH_DIR)/results/historical/*/ >/dev/null 2>&1; then \
	  for d in $$(ls -d $(BENCH_DIR)/results/historical/*/ 2>/dev/null); do \
	    run=$$(basename $$d); \
	    reports=$$(ls $$d/reports/*.md 2>/dev/null | wc -l); \
	    raw=$$(ls $$d/raw/*.json 2>/dev/null | wc -l); \
	    echo "  $$run  ($$raw raw, $$reports reports)"; \
	  done; \
	else \
	  echo "  No historical runs found."; \
	fi
	@echo ""
	@echo "Reports:"
	@ls -1 $(BENCH_DIR)/results/reports/*.md 2>/dev/null | sed 's/^/  /' || echo "  No reports yet."
	@echo ""
	@echo "Comparisons:"
	@ls -1 $(BENCH_DIR)/results/comparisons/*.md 2>/dev/null | sed 's/^/  /' || echo "  No comparisons yet."

bench-stats:
	@echo "Benchmark storage summary:"
	@echo "-------------------------"
	@du -sh $(BENCH_DIR)/results/ 2>/dev/null || echo "  No results"
	@du -sh $(BENCH_DIR)/projects/ 2>/dev/null || echo "  No projects"
	@du -sh $(BENCH_DIR)/dashboards/ 2>/dev/null || echo "  No dashboards"

bench-clean:
	@echo "Cleaning generated benchmark data..."
	rm -rf $(BENCH_DIR)/projects/ $(BENCH_DIR)/results/ $(BENCH_DIR)/dashboards/ startup_tmp.log
	@echo "Cleaned. (Source scripts and config preserved.)"

# Legacy aliases (backward compatible)
bench-worst: bench-stability
	@true

.PHONY: bench-all bench-full bench-fast bench-seed bench-startup bench-lsp \
        bench-completion bench-theme bench-buffer bench-switching bench-stability \
        bench-plugin-manager bench-plugin-attribution bench-cpu bench-ts-backend \
        bench-treesitter bench-project-indexing bench-git bench-editing bench-search \
        bench-new bench-run bench-report bench-compare bench-dashboard \
        bench-clean bench-list bench-stats bench-comprehensive bench-worst
