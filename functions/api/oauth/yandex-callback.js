// GET /api/oauth/yandex/callback
const { getAdmin } = require('../../lib/firebase');

const REDIRECT_URI = 'https://flow-bot-rosy.vercel.app/api/oauth/yandex/callback';

module.exports = async function handler(req, res) {
  const { code, error } = req.query;
  if (error || !code) {
    res.redirect('flowapp://oauth?error=yandex_denied'); return;
  }

  const clientId = process.env.YANDEX_CLIENT_ID;
  const clientSecret = process.env.YANDEX_CLIENT_SECRET;

  // Обмениваем code на token
  const tokenResp = await fetch('https://oauth.yandex.ru/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: REDIRECT_URI,
    }),
  });
  const tokenData = await tokenResp.json();
  if (tokenData.error) {
    res.redirect('flowapp://oauth?error=yandex_token'); return;
  }

  // Получаем инфо о пользователе
  const userResp = await fetch('https://login.yandex.ru/info?format=json', {
    headers: { Authorization: `OAuth ${tokenData.access_token}` },
  });
  const userInfo = await userResp.json();

  const yandexId = String(userInfo.id);
  const email = userInfo.default_email ?? null;
  const displayName = userInfo.real_name ?? userInfo.login ?? `Yandex User ${yandexId}`;

  const admin = getAdmin();
  const uid = `ya_${yandexId}`;
  try {
    await admin.auth().createUser({ uid, email: email ?? undefined, displayName });
  } catch (e) {
    if (e.code !== 'auth/uid-already-exists') throw e;
  }

  if (email) {
    await admin.auth().updateUser(uid, { email }).catch(() => {});
  }

  await admin.firestore().collection('yandexUsers').doc(yandexId).set(
    { uid, yandexId, email, displayName, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );

  const firebaseToken = await admin.auth().createCustomToken(uid);
  res.redirect(`flowapp://oauth?token=${encodeURIComponent(firebaseToken)}`);
};
