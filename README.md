# Claude Watchdog 🐕

OpenClaw skill that monitors Anthropic/Claude API health and notifies via Telegram.

## Features

- **Status monitor**: polls `status.claude.com` every 15 min, alerts with incident name, affected model, latest update
- **Latency probe**: synthetic request through OpenClaw completions API, rolling baseline, spike alerts

## Install

```bash
clawhub install claude-watchdog
```

Or install the `.skill` file manually via OpenClaw.

## Status

🚧 In development — packaging in progress
