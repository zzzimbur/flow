// POST /api/link-code — создать 6-значный код привязки (вызывается из Flutter-приложения).
// Требует Firebase ID token в заголовке Authorization: Bearer <idToken>.
const crypto = require('crypto');
const { getAdmin } = require('../lib/firebase');

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') { res.status(405).end(); return; }

  const authorization = req.headers.authorization ?? '';
  const idToken = authorization.startsWith('Bearer ') ? authorization.slice(7) : null;
  if (!idToken) { res.status(401).json({ error: 'missing token' }); return; }

  const admin = getAdmin();
  let decoded;
  try {
    decoded = await admin.auth().verifyIdToken(idToken);
  } catch {
    res.status(401).json({ error: 'invalid token' }); return;
  }

  const code = crypto.randomBytes(4).toString('hex').toUpperCase().slice(0, 6);
  await admin.firestore().collection('linkCodes').doc(code).set({
    uid: decoded.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 15 * 60 * 1000),
  });

  res.json({ code, expiresInMinutes: 15 });
};
