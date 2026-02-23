---
name: anthropic-monitor
description: Monitor Anthropic/Claude API for outages and latency spikes with rich Telegram alerts. Set up API monitoring, status alerts, and latency probes.
---

# Anthropic Monitor

Monitor the Anthropic/Claude API for outages and latency spikes. Sends rich alerts to Telegram — no agent tokens consumed for status checks.

## What It Does

### Status Monitor (`status-check.py`)
- Polls `status.claude.com` every 15 minutes via cron
- Alerts with incident name, latest update text, per-component status
- Tags incidents as "(not our model)" if e.g. Haiku is affected but you use Sonnet
- Sends all-clear on recovery
- **Zero token cost**

### Latency Probe (`latency-probe.py`)
- Sends a minimal request through OpenClaw's local gateway every 15 minutes
- Measures real end-to-end latency to Anthropic API
- Maintains rolling baseline (median of last 20 samples)
- Alerts with 🟡/🟠/🔴 severity based on spike magnitude
- Sends all-clear when latency recovers
- **~$0.000001 per probe**

## Setup

Run the interactive setup script:

```bash
bash /path/to/skills/anthropic-monitor/scripts/setup.sh
```

You'll need:
1. **Telegram Bot Token** — from [@BotFather](https://t.me/BotFather)
2. **Telegram Chat ID** — send a message to your bot, then check `https://api.telegram.org/bot<TOKEN>/getUpdates`
3. **OpenClaw Gateway Token** — run: `python3 -c "import json; print(json.load(open('~/.openclaw/openclaw.json'))['gateway']['auth']['token'])"`
4. **Gateway Port** — default `18789`

The setup script writes config, installs cron jobs, and runs an initial check.

## Config

Stored in `~/.openclaw/workspace/memory/anthropic-monitor.env`:

```
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
OPENCLAW_GATEWAY_TOKEN=...
OPENCLAW_GATEWAY_PORT=18789
```

Scripts also accept these as environment variables (env file takes priority).

## Alert Examples

**Status incident:**
```
🟠 Anthropic Status: Partially Degraded Service

📌 Elevated error rates on Claude 3.5 Haiku (not our model)
Status: Investigating
Update: "We are investigating increased error rates..."

Components:
  🟠 API: partial outage

🔗 https://status.claude.com
```

**Latency spike:**
```
🟡 Anthropic API — High Latency Detected

Current: 12.3s
Baseline: 3.1s (median of last 19 samples)
Ratio: 4.0×

Slow responses are expected right now.
```

**Recovery:**
```
✅ Anthropic API — Latency Back to Normal

Current: 2.8s
Baseline: 3.1s
Was: 12.3s when alert fired
```

## State & Logs

| File | Purpose |
|------|---------|
| `~/.openclaw/workspace/memory/anthropic-monitor-status.json` | Status check state |
| `~/.openclaw/workspace/memory/anthropic-monitor-latency.json` | Latency probe state & samples |
| `~/.openclaw/workspace/memory/anthropic-status.log` | Status check log |
| `~/.openclaw/workspace/memory/anthropic-latency.log` | Latency probe log |

## Tuning Thresholds

Edit constants at the top of `latency-probe.py`:

| Constant | Default | Meaning |
|----------|---------|---------|
| `ALERT_MULTIPLIER` | 2.5 | Alert if latency > N× baseline median |
| `ALERT_HARD_FLOOR` | 10.0s | Always alert above this absolute threshold |
| `RECOVER_MULTIPLIER` | 1.5 | Clear alert when below N× baseline |
| `BASELINE_WINDOW` | 20 | Rolling sample window size |
| `BASELINE_MIN_SAMPLES` | 5 | Minimum samples before alerting starts |
| `PROBE_TIMEOUT` | 45s | Give up on probe after this long |

## Requirements

- Python 3.10+ (stdlib only, no pip dependencies)
- OpenClaw gateway running locally
- Telegram bot with access to the target chat
