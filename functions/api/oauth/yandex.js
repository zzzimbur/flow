// GET /api/oauth/yandex — Yandex ID OAuth flow
// Требует: YANDEX_CLIENT_ID, YANDEX_CLIENT_SECRET
const REDIRECT_URI = 'https://flow-bot-rosy.vercel.app/api/oauth/yandex/callback';

module.exports = async function handler(req, res) {
  const clientId = process.env.YANDEX_CLIENT_ID;
  if (!clientId) { res.status(500).send('YANDEX_CLIENT_ID not set'); return; }

  const url = new URL('https://oauth.yandex.ru/authorize');
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  res.redirect(url.toString());
};
