// GET /api/oauth/vk — VK ID OAuth flow
// Шаг 1: редирект на VK
// Шаг 2: VK редиректит на /api/oauth/vk/callback
// Требует переменные: VK_CLIENT_ID, VK_CLIENT_SECRET
const { getAdmin } = require('../../lib/firebase');

const REDIRECT_URI = 'https://flow-bot-rosy.vercel.app/api/oauth/vk/callback';

module.exports = async function handler(req, res) {
  const clientId = process.env.VK_CLIENT_ID;
  if (!clientId) { res.status(500).send('VK_CLIENT_ID not set'); return; }

  const url = new URL('https://oauth.vk.com/authorize');
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('redirect_uri', REDIRECT_URI);
  url.searchParams.set('scope', 'email');
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('v', '5.131');
  res.redirect(url.toString());
};
