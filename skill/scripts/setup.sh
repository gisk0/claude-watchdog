#!/usr/bin/env bash
set -euo pipefail

# setup.sh — Interactive setup for anthropic-monitor skill

ENV_FILE="$HOME/.openclaw/workspace/memory/anthropic-monitor.env"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Anthropic Monitor — Setup ==="
echo ""

# 1. Telegram Bot Token
echo "Telegram Bot Token (get from @BotFather on Telegram):"
read -rp "> " bot_token
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

# 3. OpenClaw Gateway Token
echo ""
echo "OpenClaw Gateway Token (find with:"
echo "  python3 -c \"import json; print(json.load(open('$HOME/.openclaw/openclaw.json'))['gateway']['auth']['token'])\""
echo "):"
read -rp "> " gw_token
if [[ -z "$gw_token" ]]; then
    echo "ERROR: Gateway token is required." >&2
    exit 1
fi

# 4. Gateway port (default 18789)
echo ""
read -rp "OpenClaw Gateway Port [18789]: " gw_port
gw_port="${gw_port:-18789}"

# Write env file
mkdir -p "$(dirname "$ENV_FILE")"
cat > "$ENV_FILE" <<EOF
TELEGRAM_BOT_TOKEN=$bot_token
TELEGRAM_CHAT_ID=$chat_id
OPENCLAW_GATEWAY_TOKEN=$gw_token
OPENCLAW_GATEWAY_PORT=$gw_port
EOF
echo ""
echo "Config written to $ENV_FILE"

# 5. Install cron jobs
STATUS_SCRIPT="$SKILL_DIR/scripts/status-check.py"
LATENCY_SCRIPT="$SKILL_DIR/scripts/latency-probe.py"

# Remove old entries if any
crontab -l 2>/dev/null | grep -v 'anthropic-monitor' | grep -v 'status-check\.py' | grep -v 'latency-probe\.py' > /tmp/crontab-clean || true
{
    cat /tmp/crontab-clean
    echo "*/15 * * * * /usr/bin/python3 $STATUS_SCRIPT >> /dev/null 2>&1 # anthropic-monitor"
    echo "*/15 * * * * /usr/bin/python3 $LATENCY_SCRIPT >> /dev/null 2>&1 # anthropic-monitor"
} | crontab -
rm -f /tmp/crontab-clean

echo "Cron jobs installed (every 15 minutes)."

# 6. Run initial status check
echo ""
echo "Running initial status check..."
if /usr/bin/python3 "$STATUS_SCRIPT"; then
    echo "✓ Status check passed."
else
    echo "✗ Status check failed — check config." >&2
    exit 1
fi

echo ""
echo "=== Setup complete ==="
echo "Alerts will be sent to Telegram chat $chat_id."
echo "State files: ~/.openclaw/workspace/memory/anthropic-monitor-*.json"
echo "Logs: ~/.openclaw/workspace/memory/anthropic-*.log"
