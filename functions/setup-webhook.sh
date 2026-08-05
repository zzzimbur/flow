#!/bin/bash
# Привязывает Telegram-вебхук к Vercel.
# Использование: ./setup-webhook.sh <BOT_TOKEN> <VERCEL_URL>
# Пример: ./setup-webhook.sh 123:ABC https://flow-bot.vercel.app
set -euo pipefail

TOKEN="${1:?Использование: ./setup-webhook.sh <BOT_TOKEN> <VERCEL_URL>}"
BASE_URL="${2:?Использование: ./setup-webhook.sh <BOT_TOKEN> <VERCEL_URL>}"
WEBHOOK_URL="${BASE_URL%/}/api/webhook"

# Должно совпадать с webhookSecret() в lib/telegram.js
SECRET=$(printf 'flow-webhook:%s' "$TOKEN" | shasum -a 256 | cut -c1-48)

echo "→ Устанавливаю вебхук: $WEBHOOK_URL"
curl -s "https://api.telegram.org/bot${TOKEN}/setWebhook" \
  -d "url=${WEBHOOK_URL}" \
  -d "secret_token=${SECRET}" \
  -d "drop_pending_updates=true"
echo
echo "→ Статус вебхука:"
curl -s "https://api.telegram.org/bot${TOKEN}/getWebhookInfo" | python3 -m json.tool
