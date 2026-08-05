// GET /api/oauth/telegram/callback — Telegram передаёт данные пользователя
const crypto = require('crypto');
const { getAdmin } = require('../../lib/firebase');

module.exports = async function handler(req, res) {
  const { hash, ...data } = req.query;
  if (!hash) { res.redirect('flowapp://oauth?error=no_hash'); return; }

  // Проверяем подпись от Telegram
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  const secretKey = crypto.createHash('sha256').update(botToken).digest();
  const dataCheckString = Object.keys(data).sort().map(k => `${k}=${data[k]}`).join('\n');
  const computedHash = crypto.createHmac('sha256', secretKey).update(dataCheckString).digest('hex');

  if (computedHash !== hash) {
    res.redirect('flowapp://oauth?error=invalid_hash'); return;
  }

  // Проверяем свежесть (не старше 10 минут)
  const authDate = parseInt(data.auth_date, 10);
  if (Date.now() / 1000 - authDate > 600) {
    res.redirect('flowapp://oauth?error=expired'); return;
  }

  const tgId = String(data.id);
  const displayName = [data.first_name, data.last_name].filter(Boolean).join(' ');
  const uid = `tg_${tgId}`;

  const admin = getAdmin();

  // Создаём Firebase пользователя если нет
  try {
    await admin.auth().createUser({ uid, displayName: displayName || `TG ${tgId}` });
  } catch (e) {
    if (e.code !== 'auth/uid-already-exists') throw e;
  }

  // Синхронизируем с telegramUsers — бот сразу будет его видеть
  await admin.firestore().collection('telegramUsers').doc(tgId).set({
    uid,
    telegramId: tgId,
    username: data.username || null,
    firstName: data.first_name || null,
    lastName: data.last_name || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  const firebaseToken = await admin.auth().createCustomToken(uid);
  res.redirect(`flowapp://oauth?token=${encodeURIComponent(firebaseToken)}`);
};
