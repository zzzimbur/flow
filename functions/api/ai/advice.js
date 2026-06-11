export const config = { maxDuration: 30 };

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).end();

  const { message, context, history = [], uid, sessionId } = req.body || {};
  if (!message) return res.status(400).json({ error: 'No message' });

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'ANTHROPIC_API_KEY not configured' });

  const ctx = context || {};
  const systemPrompt = `Ты Flow AI — персональный финансовый советник и аналитик по сменам.
Отвечаешь по-русски, кратко (2-4 предложения), конкретно и по делу. Используй эмодзи в меру.

Данные пользователя (текущий месяц):
— Заработано на сменах: ${ctx.shiftEarnings ?? '—'} ₽ (${ctx.shiftCount ?? '—'} смен)
— Средняя смена: ${ctx.avgShift ?? '—'} ₽
— Доходы всего: ${ctx.totalIncome ?? '—'} ₽
— Расходы: ${ctx.totalExpense ?? '—'} ₽
— Баланс: ${ctx.balance ?? '—'} ₽
— Прогноз на следующий месяц: ${ctx.forecast ?? '—'} ₽
— Норма сбережений: ${ctx.savingsRate ?? '—'}%
— Топ расходы: ${ctx.topExpenseCategories ?? '—'}`;

  // Build messages: history (last 8 turns) + new message
  const messages = [
    ...history.slice(-8),
    { role: 'user', content: message },
  ];

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 512,
        system: systemPrompt,
        messages,
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      return res.status(502).json({ error: 'API error', details: err });
    }

    const data = await response.json();
    const reply = data.content?.[0]?.text ?? 'Не удалось получить ответ.';

    // Save to Firestore if uid provided
    if (uid && sessionId && process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const { initializeApp, cert, getApps } = await import('firebase-admin/app');
        const { getFirestore } = await import('firebase-admin/firestore');
        const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        const app = getApps().length ? getApps()[0] : initializeApp({ credential: cert(sa) });
        const db = getFirestore(app);
        const ts = new Date();
        const ref = db.collection('users').doc(uid).collection('aiChats').doc(sessionId).collection('messages');
        await Promise.all([
          ref.add({ role: 'user', content: message, createdAt: ts }),
          ref.add({ role: 'assistant', content: reply, createdAt: ts }),
          db.collection('_aiStats').doc('global').set({
            totalMessages: (await import('firebase-admin/firestore')).FieldValue.increment(1),
          }, { merge: true }),
        ]);
      } catch (_) { /* non-fatal */ }
    }

    res.json({ reply });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
