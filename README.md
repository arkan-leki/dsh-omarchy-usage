# dsh-omarchy-usage

Track **DeepSeek Harness (dsh)** token usage in the **Omarchy agents panel**.

The Omarchy agents bar widget normally only ships collectors for claude, codex
and fireworks. This is a community collector that makes the panel show a
**DeepSeek** tab with your real dsh usage — requests, tokens per day, and
tokens per model.

## What it does

Reads dsh session transcripts and prints an Omarchy usage record:

- **Source:** `~/.dsh/sessions/*/*/session.jsonl.zstd` (compressed JSONL)
- **Counting:** one entry per `assistant/message` event (= one real API call, matching DeepSeek platform accounting)
- **Models:** read from `data.message.source.model` (flash, vision, pro, local...)
- **Output:** today's prompts/tokens, last 7 days, and all-time per-model buckets
- **Destination:** `~/.local/state/omarchy/agents/usage/dsh.json` — the agents panel auto-discovers any record in this directory

> Note: this tracks **dsh sessions only** — usage from opencode, vscode or other
> apps using your DeepSeek key is *not* included (see the DeepSeek platform
> dashboard for the full bill).

## Install

```bash
# 1. Collector
install -m755 omarchy-agent-usage-dsh ~/.local/bin/

# 2. Optional: auto-refresh every 15 minutes (systemd user timer)
mkdir -p ~/.config/systemd/user
cp dsh-usage.service dsh-usage.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now dsh-usage.timer

# 3. Run once (or wait for the timer)
~/.local/bin/omarchy-agent-usage-dsh > ~/.local/state/omarchy/agents/usage/dsh.json

# 4. Make the panel show it
omarchy refresh
```

## The record format

```json
{
  "schemaVersion": 1,
  "id": "dsh",
  "name": "DeepSeek",
  "todayPrompts": 38,
  "todayTotalTokens": 15068760,
  "recentDays": [{"date": "2026-09-02", "tokens": 15068760}],
  "modelUsage": {
    "deepseek-v4-flash": {"inputTokens": 2277018, "outputTokens": 1944939, "cacheReadInputTokens": 844637952}
  }
}
```

## Disclaimer

Token counts are approximate — they reflect what dsh logs locally, and cache
read tokens inflate the totals. Use the DeepSeek platform for exact billing.
