// GET /api/oauth/telegram — редирект на Telegram Login
module.exports = function handler(req, res) {
  const botId = process.env.TELEGRAM_BOT_ID || '8749125120';
  const returnTo = encodeURIComponent('https://flow-bot-rosy.vercel.app/api/oauth/telegram/callback');
  res.redirect(`https://oauth.telegram.org/auth?bot_id=${botId}&scope=users_read&return_to=${returnTo}&origin=https://flow-bot-rosy.vercel.app`);
};
