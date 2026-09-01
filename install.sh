#!/bin/bash
# dsh-omarchy-usage installer — one command, done.
set -e

echo "==> Installing collector..."
install -m755 omarchy-agent-usage-dsh ~/.local/bin/

echo "==> Setting up auto-refresh timer (every 15 min)..."
mkdir -p ~/.config/systemd/user
cp dsh-usage.service dsh-usage.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now dsh-usage.timer

echo "==> Generating usage record..."
mkdir -p ~/.local/state/omarchy/agents/usage
~/.local/bin/omarchy-agent-usage-dsh > ~/.local/state/omarchy/agents/usage/dsh.json

echo "==> Enabling dsh in the agents panel (keeps your other agents)..."
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.config/omarchy/shell.json")
with open(p) as f:
    d = json.load(f)
def walk(o):
    if isinstance(o, dict):
        if o.get("id") == "omarchy.agents":
            prov = o.get("providers") or {}
            prov["dsh"] = {"enabled": True}
            o["providers"] = prov
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)
walk(d)
with open(p, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
print("   added dsh to omarchy.agents providers")
PY

echo "==> Reloading the shell..."
export OMARCHY_PATH=/usr/share/omarchy
omarchy-shell shell reloadConfig >/dev/null 2>&1 || true

echo ""
echo "✅ Done! Check your top bar — you should see the DeepSeek Harness tab."
echo "   (Refresh the shell with: omarchy refresh, if it doesn't appear right away.)"
