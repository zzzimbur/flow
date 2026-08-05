const crypto = require('crypto');

async function tgApi(botToken, method, payload) {
  const response = await fetch(`https://api.telegram.org/bot${botToken}/${method}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const json = await response.json();
  if (!json.ok) {
    console.error(`Telegram ${method} failed:`, json);
  }
  return json;
}

function sendMessage(botToken, chatId, text, extra = {}) {
  return tgApi(botToken, 'sendMessage', {
    chat_id: chatId,
    text,
    parse_mode: 'HTML',
    ...extra,
  });
}

// Секрет вебхука выводим из токена бота, чтобы не заводить отдельный секрет.
function webhookSecret(botToken) {
  return crypto.createHash('sha256').update(`flow-webhook:${botToken}`).digest('hex').slice(0, 48);
}

// Проверка подписи initData из Telegram Mini App.
// https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
function verifyInitData(initData, botToken) {
  const params = new URLSearchParams(initData);
  const hash = params.get('hash');
  if (!hash) return null;
  params.delete('hash');

  const dataCheckString = [...params.entries()]
    .map(([k, v]) => `${k}=${v}`)
    .sort()
    .join('\n');

  const secretKey = crypto.createHmac('sha256', 'WebAppData').update(botToken).digest();
  const computed = crypto.createHmac('sha256', secretKey).update(dataCheckString).digest('hex');
  if (computed !== hash) return null;

  const authDate = parseInt(params.get('auth_date') || '0', 10);
  if (Date.now() / 1000 - authDate > 86400) return null; // initData старше суток

  try {
    return JSON.parse(params.get('user') || 'null');
  } catch {
    return null;
  }
}

module.exports = { tgApi, sendMessage, webhookSecret, verifyInitData };
