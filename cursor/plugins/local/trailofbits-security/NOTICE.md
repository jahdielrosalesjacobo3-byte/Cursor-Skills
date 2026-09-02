# trailofbits-security — vendored subset

Upstream: https://github.com/trailofbits/skills (commit `14e5a10`, marketplace `trailofbits`, 42 plugins).
License: CC BY-SA 4.0 (see `LICENSE`). Attribution preserved; skill bodies unmodified.

## Why a local Cursor plugin

Cursor has no CLI to add third-party marketplaces; local plugins load from
`~/.cursor/plugins/local/<name>/` with a `.cursor-plugin/plugin.json`. This folder
aggregates 21 upstream plugins into one Cursor plugin so the K3 router sees a single
L1 unit (`skills/` + `agents/`).

## Layout differences vs upstream

| Upstream | Here |
|----------|------|
| `plugins/<p>/skills/<s>/` | `skills/<s>/` (flattened, names are unique) |
| `plugins/<p>/agents/*.md` | `agents/*.md` |
| `plugins/<p>/workflows/*.js` | `workflows/*.js` (flattened, no name collisions) |
| `plugins/<p>/hooks/hooks.json` | **not vendored** (gh-cli, modern-python, fp-check) |
| `plugins/<p>/.mcp.json` | **not vendored** (second-opinion) |
| `plugins/<p>/tests/` | not vendored |

`${CLAUDE_PLUGIN_ROOT}` in skill text = this plugin directory. Skills that search
for it fall back to a filesystem search, so relocation is safe.

## Claude Code

Use the upstream marketplace directly instead of this copy:

```
/plugin marketplace add trailofbits/skills
/plugin install trailofbits/skills/plugins/static-analysis
```

## Refresh

```bash
bash scripts/vendor-trailofbits.sh   # re-clone upstream and rebuild this folder
```
