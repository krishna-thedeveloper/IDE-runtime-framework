# Updating

## Update Plugins

```vim
:Lazy update
```

Or from the command line:

```bash
nvim --headless "+Lazy! update" +qa
```

## Update the Configuration

If you cloned this repository:

```bash
cd ~/.config/nvim
git pull
```

After pulling, run `:Lazy restart` or restart Neovim to pick up changes.

## Lockfile

`lazy-lock.json` at the repository root pins every plugin to a specific commit. This ensures reproducible installs across machines.

- **Do not delete** `lazy-lock.json`.
- When adding a new plugin, its entry appears here after the first successful install.
- The lockfile should be committed to version control.

## Reverting

If an update breaks something:

```bash
cd ~/.config/nvim
git log --oneline -10
git revert HEAD  # or checkout a specific commit
```

Then restart Neovim. Lazy.nvim will restore the pinned versions from `lazy-lock.json`.

## Breaking Changes

This configuration follows semantic versioning (TODO: add tags). Major version bumps may include:

- Plugin swaps (e.g., Telescope → Snacks as default).
- Manager API changes.
- File structure renames.

Check [Migration History](../decisions/migration-history.md) before upgrading across major versions.

---

**Previous:** [First Launch](first-launch.md)
**Up:** [Getting Started](../getting-started/installation.md)
