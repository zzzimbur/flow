// POST /api/auth — mini app: Telegram initData → Firebase custom token
const { getAdmin } = require('../lib/firebase');
const { verifyInitData } = require('../lib/telegram');

async function ensureTelegramUser(admin, tgUser) {
  const db = admin.firestore();
  const mappingRef = db.collection('telegramUsers').doc(String(tgUser.id));
  const mapping = await mappingRef.get();
  if (mapping.exists) return mapping.data().uid;

  const uid = `tg_${tgUser.id}`;
  try {
    await admin.auth().createUser({
      uid,
      displayName: [tgUser.first_name, tgUser.last_name].filter(Boolean).join(' ') || tgUser.username || 'Telegram user',
    });
  } catch (e) {
    if (e.code !== 'auth/uid-already-exists') throw e;
  }

  await mappingRef.set({
    uid,
    telegramId: tgUser.id,
    username: tgUser.username ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return uid;
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') { res.status(200).end(); return; }
  if (req.method !== 'POST') { res.status(405).end(); return; }

  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  if (!botToken) { res.status(500).json({ error: 'no bot token' }); return; }

  const tgUser = verifyInitData(req.body?.initData ?? '', botToken);
  if (!tgUser) { res.status(401).json({ error: 'invalid initData' }); return; }

  const admin = getAdmin();
  const uid = await ensureTelegramUser(admin, tgUser);
  const token = await admin.auth().createCustomToken(uid);
  res.json({ token, uid });
};
