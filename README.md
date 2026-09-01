# dsh-omarchy-usage

Track **DeepSeek Harness (dsh)** usage in the **Omarchy agents panel**.

The Omarchy agents bar widget ships collectors only for claude, codex and fireworks.
This is a community collector that adds a **DeepSeek Harness** tab showing your real
dsh usage — requests, tokens per day, and tokens per model.

## Features

- Tracks **every model** used through dsh: deepseek flash / vision / pro, Gemini, local Ollama models, etc.
- Counts **one entry per assistant message** (= one real API call, matching DeepSeek platform accounting)
- Shows **today**, **last 7 days**, and **all-time** token totals
- Per-model breakdown with input / output / cache-read split
- **Auto-refreshes every 15 minutes** (systemd user timer)

## How it works

1. dsh writes every conversation to `~/.dsh/sessions/<project>/<session-id>/session.jsonl.zstd` (zstd-compressed JSONL).
2. The collector decompresses each file and reads every `assistant/message` event.
3. From each event it extracts: timestamp (→ day), model (`data.message.source.model`), and token usage (`data.usage`).
4. It aggregates into a usage record and prints it.
5. The record lands in `~/.local/state/omarchy/agents/usage/dsh.json` — the agents panel auto-discovers any record in this directory.

## Install

```bash
# 1. Install the collector
install -m755 omarchy-agent-usage-dsh ~/.local/bin/

# 2. Auto-refresh every 15 minutes (systemd user timer)
mkdir -p ~/.config/systemd/user
cp dsh-usage.service dsh-usage.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now dsh-usage.timer

# 3. Generate the record once
~/.local/bin/omarchy-agent-usage-dsh > ~/.local/state/omarchy/agents/usage/dsh.json

# 4. Enable dsh in the agents panel (required — see below)
# 5. Refresh the shell
omarchy-shell shell reloadConfig   # or: omarchy refresh
```

## Enable in the agents panel (important)

The agents widget only shows enabled agents. Add `dsh` to the providers config of the
`omarchy.agents` widget in `~/.config/omarchy/shell.json` — **keep your existing
agents; just add dsh** (any agent not listed defaults to enabled):

```json
{
  "id": "omarchy.agents",
  "providers": {
    "dsh": {"enabled": true}
  }
}
```

Or via the CLI:

```bash
omarchy bar set omarchy.agents providers '{"dsh":{"enabled":true}}' --json
```

Then reload the shell (`omarchy-shell shell reloadConfig` or `omarchy refresh`).

## The record format

```json
{
  "schemaVersion": 1,
  "id": "dsh",
  "name": "DeepSeek Harness",
  "ready": true,
  "hasLocalStats": true,
  "todayPrompts": 38,
  "todayTotalTokens": 15068760,
  "todayTokensByModel": {"deepseek-v4-flash": 15068760},
  "recentDays": [{"date": "2026-09-02", "messageCount": 38, "tokens": 15068760}],
  "modelUsage": {
    "deepseek-v4-flash": {"inputTokens": 2277018, "outputTokens": 1944939, "cacheReadInputTokens": 844637952, "cacheCreationInputTokens": 0}
  }
}
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Panel never appears | `dsh` not in providers config (see above), or record missing/invalid — run the collector and check `~/.local/state/omarchy/agents/usage/dsh.json` |
| Record shows zero | No `assistant/message` events with usage in `~/.dsh/sessions` — check you have dsh sessions with token usage |
| Panel shows stale numbers | The timer refreshes every 15 min, or run the collector manually |
| Timer not running | `systemctl --user enable --now dsh-usage.timer` |

## Requirements

- dsh (DeepSeek Harness) with recorded sessions
- `zstd` (for decompressing session files)
- Omarchy 4.x (Quickshell agents panel)

## Disclaimer

Token counts are **approximate** — they reflect what dsh logs locally, and cache-read
tokens inflate the totals (a long session re-reads context on every call). This tracks
**dsh sessions only** — usage from opencode, vscode or other apps using your DeepSeek
key is not included. For exact billing, use the DeepSeek platform dashboard.

## License

MIT