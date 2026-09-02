# Optional MCP servers (documented, not installed)

Verified 2026-09-02. Each entry is a drop-in block for `~/.cursor/mcp.json` (or a
project `.cursor/mcp.json`). They are **not** in `cursor/mcp.json` because they need an
account you may not have, a heavy runtime (Docker) at Cursor start, or they overlap
with an installed server. Never paste literal secrets — use `${env:VAR}` or OAuth.

## Sentry (errors, traces, Seer root-cause) — OAuth

Pairs with `observability-engineer` and Vercel `get_runtime_errors`.

```json
"sentry": { "url": "https://mcp.sentry.dev/mcp/{org}/{project}" }
```

Drop `/{org}/{project}` to scope to all orgs. First connect opens the browser.

## HashiCorp Terraform (registry docs, module/provider lookup) — Docker

Pairs with `iac-security.mdc`, `10-cloud-security`, `snyk_iac_scan`.

```json
"terraform": { "command": "docker", "args": ["run", "-i", "--rm", "hashicorp/terraform-mcp-server"] }
```

## AWS API MCP (operate an account; SigV4 via local credentials)

The keyless `aws-knowledge` server is already installed for docs. Add this only when an
agent must **act** on AWS. AWS recommends not running both knowledge + API long-term.

```json
"aws-api": { "command": "uvx", "args": ["awslabs.aws-api-mcp-server@latest"], "env": { "AWS_PROFILE": "default", "AWS_REGION": "us-east-1", "FASTMCP_LOG_LEVEL": "ERROR" } }
```

## Firecrawl (scrape / crawl to markdown) — API key

```json
"firecrawl": { "command": "npx", "args": ["-y", "firecrawl-mcp"], "env": { "FIRECRAWL_API_KEY": "${env:FIRECRAWL_API_KEY}" } }
```

## Exa (neural web search for deep-researcher) — API key

```json
"exa": { "url": "https://mcp.exa.ai/mcp", "headers": { "x-api-key": "${env:EXA_API_KEY}" } }
```

Cursor's built-in `WebSearch` / `WebFetch` cover most research; add Exa for
citation-heavy dossiers.

## Playwright MCP (Microsoft) — overlaps with agent-browser

`agent-browser` (Vercel Labs, installed as plugin) is the K3 browser stack. Use this only
if a task needs Playwright-native tracing.

```json
"playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }
```

## GitHub token for the installed `github` server

The server is active but needs a PAT (Cursor does not do OAuth for GitHub remote yet):

```bash
gh auth login                                  # once
echo 'export GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token 2>/dev/null)}"' >> ~/.zshenv
```

`~/.zshenv` (not `.zshrc`) is what GUI Cursor inherits on macOS. Restart Cursor.

## ruflo / claude-flow tool volume

`claude-flow` exposes ~270 tools. If the catalog feels heavy in a project, disable groups:

```bash
claude-flow mcp tools --category         # list categories
claude-flow mcp toggle --disable <tool>  # persist per install
```

Or move the `claude-flow` entry to a project `.cursor/mcp.json` for swarm-heavy repos only.
