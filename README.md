# Claude Watchdog 🐕

OpenClaw skill that monitors the Claude API for outages and latency spikes, with rich Telegram alerts.

## Features

- **Status monitoring** — polls `status.claude.com` every 15 min, sends alerts with incident details, affected components, and model relevance tagging
- **Latency probing** — sends a minimal request through your OpenClaw gateway, maintains a rolling baseline, and alerts on spikes with 🟡/🟠/🔴 severity
- **Recovery alerts** — notifies when incidents resolve and latency returns to normal
- **Zero dependencies** — stdlib Python only, no pip install needed
- **Configurable** — Telegram topic targeting, model selection, tunable thresholds

## Install

```bash
clawhub install claude-watchdog
```

Then run `setup.sh` — the interactive setup walks you through connecting your Telegram bot and OpenClaw gateway.

## Docs

See [SKILL.md](skill/SKILL.md) for full configuration reference, alert examples, and tuning guide.

## Cost

- Status checks: **$0** (no API calls)
- Latency probes: **~$0.000001/probe** (minimal "Reply OK" request)
