#!/usr/bin/env bash
# Claude Code spend alarm. NOTIFY ONLY: it never blocks, kills, pauses or
# refuses anything, and always exits 0. Captain's rule, data/captain-shared.md:
# "spend meter should notify me if an unusually high spend amount is
#  approaching. not stop the worker from proceeding."
#
# Called in the background by statusline.sh. It self-rate-limits, so the
# 10-second status refresh costs nothing on most invocations.
#
# Lives in ~/dotfiles/claude/ and is invoked by absolute path, so it needs no
# nix link and no darwin-rebuild. Not in the README linked-files table for that
# reason.
set -uo pipefail
STATE="$HOME/.claude/spend-alert"
INTERVAL=120
mkdir -p "$STATE" 2>/dev/null || exit 0

stamp="$STATE/last-run"
now=$(date +%s)
if [ -f "$stamp" ]; then
  last=$(cat "$stamp" 2>/dev/null || echo 0)
  [ $((now - last)) -lt "$INTERVAL" ] && exit 0
fi
# single-flight: several sessions call this at once
mkdir "$STATE/.lock" 2>/dev/null || exit 0
trap 'rmdir "$STATE/.lock" 2>/dev/null || true' EXIT
printf '%s' "$now" > "$stamp"

python3 - "$STATE" <<'PY' 2>/dev/null || exit 0
import json, os, sys, time, datetime, subprocess
from datetime import datetime as _dt

state = sys.argv[1]
root = os.path.expanduser("~/.claude/projects")
today = datetime.date.today().isoformat()

def local_date(ts):
    # Records carry UTC ("...Z"); the day we bill against is the captain's
    # local day, so convert before bucketing. Mixing the two silently drops
    # every record written between UTC midnight and local midnight.
    try:
        return _dt.fromisoformat(ts.replace("Z", "+00:00")).astimezone().date().isoformat()
    except Exception:
        return ""

# Per-MTok list rates. Cache read is 0.1x input, cache write 1.25x (5-min TTL).
RATES = {  # (input, output)
    "opus":   (5.0, 25.0),
    "fable":  (10.0, 50.0),
    "sonnet": (3.0, 15.0),
    "haiku":  (1.0, 5.0),
}
def rate(model):
    m = (model or "").lower()
    for k, v in RATES.items():
        if k in m:
            return v
    return RATES["opus"]          # unknown model: price it as the dearest tier

# Daily thresholds, set from 18 days of measured history: median working day
# $505, busiest normal day $1148, the 2026-08-19 fan-out blowout $1919.
DAILY  = [(900, "notice"), (1300, "warn"), (1800, "high")]
BURN   = 150.0                    # $/hr; normal busy day runs about $67/hr

cur_path = os.path.join(state, "cursors.json")
try:
    cur = json.load(open(cur_path))
except Exception:
    cur = {}
if cur.get("date") != today:
    cur = {"date": today, "files": {}, "cost": 0.0, "recent": []}

files = cur.setdefault("files", {})
cold = not files          # first run of the day: seed, never alarm
recent = cur.setdefault("recent", [])   # [(epoch, cost)] for the burn window
day_start = time.mktime(datetime.date.today().timetuple())
added = 0.0

for dirpath, _dirnames, filenames in os.walk(root):
    for fn in filenames:
        if not fn.endswith(".jsonl"):
            continue
        p = os.path.join(dirpath, fn)
        try:
            st = os.stat(p)
        except OSError:
            continue
        if st.st_mtime < day_start:      # nothing written today
            continue
        off = files.get(p, 0)
        if st.st_size < off:             # rotated or truncated
            off = 0
        if st.st_size == off:
            continue
        try:
            fh = open(p, errors="replace")
        except OSError:
            continue
        with fh:
            fh.seek(off)
            for line in fh:
                if '"usage"' not in line:
                    continue
                try:
                    r = json.loads(line)
                except Exception:
                    continue
                if local_date(r.get("timestamp", "")) != today:
                    continue
                m = r.get("message") or {}
                u = m.get("usage") or {}
                if not u:
                    continue
                inp, outp = rate(m.get("model"))
                c = (u.get("cache_read_input_tokens", 0) * inp * 0.1
                     + u.get("cache_creation_input_tokens", 0) * inp * 1.25
                     + u.get("input_tokens", 0) * inp
                     + u.get("output_tokens", 0) * outp) / 1e6
                added += c
            files[p] = fh.tell()

cur["cost"] = cur.get("cost", 0.0) + added
# A cold run backfills the whole day at once. Charging that to the current
# minute would invent a huge burn rate and fire every threshold at once.
if added and not cold:
    recent.append([int(time.time()), round(added, 4)])
cutoff = time.time() - 3600
cur["recent"] = [x for x in recent if x[0] >= cutoff]
burn = sum(x[1] for x in cur["recent"])
cost = cur["cost"]

tmp = cur_path + ".tmp"
json.dump(cur, open(tmp, "w"))
os.replace(tmp, cur_path)

def notify(title, msg):
    subprocess.run(["osascript", "-e",
        'display notification "%s" with title "%s"' % (msg.replace('"', "'"),
                                                       title.replace('"', "'"))],
        capture_output=True)

fired_path = os.path.join(state, "fired.json")
try:
    fired = json.load(open(fired_path))
except Exception:
    fired = {}
if fired.get("date") != today:
    fired = {"date": today}

if cold:
    # Mark whatever today already exceeded as seen, so only NEW crossings alarm.
    for limit, label in DAILY:
        if cost >= limit:
            fired[label] = True
    fired["burn_at"] = time.time()

for limit, label in DAILY:
    if cost >= limit and not fired.get(label):
        fired[label] = True
        notify("Claude spend %s" % label,
               "Today $%.0f, past $%d. Burn $%.0f/hr. Nothing stopped." % (cost, limit, burn))

if burn >= BURN and (time.time() - fired.get("burn_at", 0)) >= 3600:
    fired["burn_at"] = time.time()
    notify("Claude burn rate high",
           "$%.0f/hr right now, today $%.0f. Normal busy is ~$67/hr." % (burn, cost))

json.dump(fired, open(fired_path, "w"))

# Publish for the status bar. Never fatal.
line = "$%.0f today · $%.0f/hr" % (cost, burn)
open(os.path.join(state, "current"), "w").write(line + "\n")
pane = os.environ.get("TMUX_PANE")
if pane:
    subprocess.run(["tmux", "set", "-p", "-t", pane, "@claude_spend", line],
                   capture_output=True)
PY
exit 0
