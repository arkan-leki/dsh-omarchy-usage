#!/bin/bash
# dsh-omarchy-usage installer — one command, done.
# Safety: user-space only, backs up config before editing, validates after.
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
python3 -c "import json; json.load(open('$HOME/.local/state/omarchy/agents/usage/dsh.json'))" && echo "   record valid"

echo "==> Enabling dsh in the agents panel (backup first, keeps other agents)..."
python3 - <<'PY'
import json, os, shutil, time
p = os.path.expanduser("~/.config/omarchy/shell.json")
if not os.path.exists(p):
    print("   WARNING: no ~/.config/omarchy/shell.json — nothing to patch.")
    print("   The panel may use defaults; if it doesn't appear, see the README.")
    raise SystemExit(0)
bak = p + ".bak-" + str(int(time.time()))
shutil.copy2(p, bak)
print("   backup saved:", os.path.basename(bak))
with open(p) as f:
    d = json.load(f)
found = []
def walk(o):
    if isinstance(o, dict):
        if o.get("id") == "omarchy.agents":
            prov = o.get("providers") or {}
            prov["dsh"] = {"enabled": True}
            o["providers"] = prov
            found.append(True)
        for v in o.values():
            walk(v)
    elif isinstance(o, list):
        for v in o:
            walk(v)
walk(d)
if not found:
    print("   WARNING: 'omarchy.agents' widget not found in shell.json — panel not enabled.")
    print("   See the README for how to add the widget. (Backup kept; nothing changed.)")
    raise SystemExit(0)
with open(p, "w") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
try:
    json.load(open(p))
    print("   shell.json valid after edit ✓ (backup saved)")
except Exception:
    shutil.copy2(bak, p)
    print("   ERROR: edit produced invalid JSON — restored backup. Aborting.")
    raise SystemExit(1)
PY

echo "==> Reloading the shell..."
if command -v omarchy-shell >/dev/null 2>&1; then
    export OMARCHY_PATH=/usr/share/omarchy
    omarchy-shell shell reloadConfig >/dev/null 2>&1 || true
else
    echo "   (omarchy-shell not found — run 'omarchy refresh' yourself after login)"
fi

echo ""
echo "✅ Done! Check your top bar — you should see the DeepSeek Harness tab."
echo "   (If it doesn't appear right away, run: omarchy refresh)"
