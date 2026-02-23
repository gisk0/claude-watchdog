#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Interactive setup for claude-watchdog skill

SKILL_DATA_DIR="$HOME/.openclaw/skills/claude-watchdog"
ENV_FILE="$SKILL_DATA_DIR/claude-watchdog.env"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON3="$(command -v python3)"

# ── uninstall ─────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--uninstall" ]]; then
    echo "=== Anthropic Monitor — Uninstall ==="
    echo ""

    # Remove cron jobs
    if crontab -l 2>/dev/null | grep -q 'claude-watchdog'; then
        crontab -l 2>/dev/null | grep -v 'claude-watchdog' | crontab -
        echo "✓ Cron jobs removed."
    else
        echo "No cron jobs found."
    fi

    # Optionally remove config/state
    if [[ -d "$SKILL_DATA_DIR" ]]; then
        echo ""
        read -rp "Also remove config and state files in $SKILL_DATA_DIR? [y/N]: " remove_data
        if [[ "${remove_data,,}" == "y" ]]; then
            rm -rf "$SKILL_DATA_DIR"
            echo "✓ Config and state files removed."
        else
            echo "Config and state files kept."
        fi
    fi

    echo ""
    echo "=== Uninstall complete ==="
    exit 0
fi

# ── setup ─────────────────────────────────────────────────────────────────────

echo "=== Anthropic Monitor — Setup ==="
echo ""

# 1. Telegram Bot Token
echo "Telegram Bot Token (get from @BotFather on Telegram):"
read -rsp "> " bot_token
echo ""
if [[ -z "$bot_token" ]]; then
    echo "ERROR: Bot token is required." >&2
    exit 1
fi

# 2. Telegram Chat ID
echo ""
echo "Telegram Chat ID (send a message to your bot, then visit"
echo "  https://api.telegram.org/bot<TOKEN>/getUpdates to find your chat ID):"
read -rp "> " chat_id
if [[ -z "$chat_id" ]]; then
    echo "ERROR: Chat ID is required." >&2
    exit 1
fi

# 3. Telegram Topic ID (optional, for forum groups)
echo ""
echo "Telegram Topic ID (optional — for forum/topic groups only)."
echo "Leave blank to send to the main/General chat."
echo "To find your topic ID, right-click a topic → Copy Link → the number after the last '/'."
read -rp "> " topic_id

# 4. OpenClaw Gateway Token
echo ""
echo "OpenClaw Gateway Token (find with:"
echo "  python3 -c \"from pathlib import Path; import json; print(json.load(open(Path.home() / '.openclaw/openclaw.json'))['gateway']['auth']['token'])\""
echo "):"
read -rsp "> " gw_token
echo ""
if [[ -z "$gw_token" ]]; then
    echo "ERROR: Gateway token is required." >&2
    exit 1
fi

# 5. Gateway port (default 18789)
echo ""
read -rp "OpenClaw Gateway Port [18789]: " gw_port
gw_port="${gw_port:-18789}"

# 6. Monitor model (default sonnet)
echo ""
read -rp "Model name to track in status incidents [sonnet]: " monitor_model
monitor_model="${monitor_model:-sonnet}"

# 7. Probe model (default openclaw)
echo ""
echo "Probe model — the model alias sent to the OpenClaw gateway for latency"
echo "probes. 'openclaw' uses the gateway's default routing."
read -rp "Probe model [openclaw]: " probe_model
probe_model="${probe_model:-openclaw}"

# 8. Probe agent ID (default main)
echo ""
read -rp "Probe agent ID (x-openclaw-agent-id header) [main]: " probe_agent_id
probe_agent_id="${probe_agent_id:-main}"

# Write env file
mkdir -p "$SKILL_DATA_DIR"
cat > "$ENV_FILE" <<EOF
TELEGRAM_BOT_TOKEN=$bot_token
TELEGRAM_CHAT_ID=$chat_id
TELEGRAM_TOPIC_ID=${topic_id:-}
OPENCLAW_GATEWAY_TOKEN=$gw_token
OPENCLAW_GATEWAY_PORT=$gw_port
MONITOR_MODEL=$monitor_model
PROBE_MODEL=$probe_model
PROBE_AGENT_ID=$probe_agent_id
EOF
chmod 600 "$ENV_FILE"
echo ""
echo "Config written to $ENV_FILE (permissions: 600)"

# 9. Install cron jobs
STATUS_SCRIPT="$SKILL_DIR/scripts/status-check.py"
LATENCY_SCRIPT="$SKILL_DIR/scripts/latency-probe.py"

# Remove old entries if any
crontab -l 2>/dev/null | grep -v 'claude-watchdog' | grep -v 'status-check\.py' | grep -v 'latency-probe\.py' > /tmp/crontab-clean || true
{
    cat /tmp/crontab-clean
    echo "*/15 * * * * $PYTHON3 $STATUS_SCRIPT >> /dev/null 2>&1 # claude-watchdog"
    echo "*/15 * * * * $PYTHON3 $LATENCY_SCRIPT >> /dev/null 2>&1 # claude-watchdog"
} | crontab -
rm -f /tmp/crontab-clean

echo "Cron jobs installed (every 15 minutes, using $PYTHON3)."

# 10. Run initial status check
echo ""
echo "Running initial status check..."
if "$PYTHON3" "$STATUS_SCRIPT"; then
    echo "✓ Status check passed."
else
    echo "✗ Status check failed — check config." >&2
    exit 1
fi

echo ""
echo "=== Setup complete ==="
echo "Alerts will be sent to Telegram chat $chat_id."
echo "State files: $SKILL_DATA_DIR/"
echo "Logs: $SKILL_DATA_DIR/"
echo ""
echo "To uninstall: bash $0 --uninstall"
