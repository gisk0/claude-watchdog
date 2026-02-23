# Claude Watchdog 🐕

Know when Claude goes down — before it ruins your workflow.

An OpenClaw skill that monitors the Claude API for outages and latency spikes, sending rich alerts straight to Telegram.

## What You Get

**Status alerts** when Anthropic reports incidents:
```
🟠 Anthropic Status: Partially Degraded Service

📌 Elevated error rates on Claude 3.5 Sonnet (⚠️ affects us)
Status: Investigating
Update: "We are investigating increased error rates..."

Components:
  🟠 API: partial outage

🔗 https://status.claude.com
```

**Latency spike detection** with severity levels:
```
🟡 Anthropic API — High Latency Detected

Current: 12.3s
Baseline: 3.1s (median of last 19 samples)
Ratio: 4.0×
```

**Recovery notifications** so you know when it's safe to go back:
```
✅ Anthropic API — Latency Back to Normal

Current: 2.8s
Baseline: 3.1s
Was: 12.3s when alert fired
```

## Features

- **Status monitoring** — polls `status.claude.com` every 15 min with incident details, affected components, and model relevance tagging ("affects us" vs "not our model")
- **Latency probing** — sends a minimal request through your OpenClaw gateway, maintains a rolling baseline, alerts on spikes with 🟡/🟠/🔴 severity
- **Recovery alerts** — notifies when incidents resolve and latency returns to normal
- **Telegram topic support** — target a specific forum topic for alerts
- **Zero dependencies** — stdlib Python only, no pip install needed
- **Tunable thresholds** — adjust alert sensitivity, baseline window, and probe timeout
- **Secure by default** — all config files `chmod 600`, secrets never logged

## Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) running on your server
- Python 3.10+
- A Telegram bot (free — create one via [@BotFather](https://t.me/BotFather))

## Install

```bash
clawhub install claude-watchdog
```

The interactive setup walks you through connecting your Telegram bot and OpenClaw gateway. It sends a test alert at the end so you know it works.

## Cost

| Component | Cost |
|-----------|------|
| Status checks | **$0** — scrapes public status page |
| Latency probes | **~$0.000001/probe** — minimal "Reply OK" request |
| Total/month | **< $0.01** |

## How It Works

```
┌─────────────┐    every 15 min    ┌──────────────────────┐
│  cron job    │──────────────────▶│  status-check.py     │
│              │                   │  • polls status.claude│
│              │                   │  • diffs vs last state│
│              │                   │  • alerts on change   │
└─────────────┘                   └──────────────────────┘
                                          │
                                          ▼ Telegram API
                                    ┌──────────┐
                                    │  Your TG  │
                                    │  chat/topic│
                                    └──────────┘
┌─────────────┐    every 15 min    ┌──────────────────────┐
│  cron job    │──────────────────▶│  latency-probe.py    │
│              │                   │  • pings OpenClaw GW  │
│              │                   │  • rolling baseline   │
│              │                   │  • alerts on spike    │
└─────────────┘                   └──────────────────────┘
```

No tokens consumed for status checks. Latency probes cost fractions of a cent per month.

## Docs

See [SKILL.md](skill/SKILL.md) for the full configuration reference, alert tuning guide, and state file details.

## License

MIT
