// GET /api/oauth/vk/callback — получаем code, меняем на token, выдаём Firebase custom token
const { getAdmin } = require('../../lib/firebase');

const REDIRECT_URI = 'https://flow-bot-rosy.vercel.app/api/oauth/vk/callback';

module.exports = async function handler(req, res) {
  const { code, error } = req.query;
  if (error || !code) {
    res.redirect('flowapp://oauth?error=vk_denied'); return;
  }

  const clientId = process.env.VK_CLIENT_ID;
  const clientSecret = process.env.VK_CLIENT_SECRET;

  // Обмениваем code на access_token
  const tokenUrl = new URL('https://oauth.vk.com/access_token');
  tokenUrl.searchParams.set('client_id', clientId);
  tokenUrl.searchParams.set('client_secret', clientSecret);
  tokenUrl.searchParams.set('redirect_uri', REDIRECT_URI);
  tokenUrl.searchParams.set('code', code);

  const tokenResp = await fetch(tokenUrl.toString());
  const tokenData = await tokenResp.json();
  if (tokenData.error) {
    res.redirect('flowapp://oauth?error=vk_token'); return;
  }

  const vkUserId = String(tokenData.user_id);
  const email = tokenData.email ?? null;

  // Создаём/получаем Firebase пользователя
  const admin = getAdmin();
  const uid = `vk_${vkUserId}`;
  try {
    await admin.auth().createUser({ uid, email: email ?? undefined, displayName: `VK User ${vkUserId}` });
  } catch (e) {
    if (e.code !== 'auth/uid-already-exists') throw e;
  }

  // Обновляем email если есть
  if (email) {
    await admin.auth().updateUser(uid, { email }).catch(() => {});
  }

  // Сохраняем маппинг VK → uid
  await admin.firestore().collection('vkUsers').doc(vkUserId).set(
    { uid, vkUserId, email, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );

  const firebaseToken = await admin.auth().createCustomToken(uid);
  res.redirect(`flowapp://oauth?token=${encodeURIComponent(firebaseToken)}`);
};
