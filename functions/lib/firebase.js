const admin = require('firebase-admin');

let initialized = false;

function getAdmin() {
  if (initialized) return admin;
  initialized = true;

  // Vercel: кладём service account JSON в переменную FIREBASE_SERVICE_ACCOUNT (base64 или raw JSON).
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  let credential;
  if (raw) {
    try {
      const json = JSON.parse(
        raw.startsWith('{') ? raw : Buffer.from(raw, 'base64').toString('utf8'),
      );
      credential = admin.credential.cert(json);
    } catch (e) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT: invalid JSON — ' + e.message);
    }
  } else {
    credential = admin.credential.applicationDefault();
  }

  admin.initializeApp({ credential, projectId: 'flowapp-25488' });
  return admin;
}

module.exports = { getAdmin };
