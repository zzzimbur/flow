export const config = { maxDuration: 30 };

const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages';
const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

async function callClaude(systemPrompt, messages) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY not configured');
  const resp = await fetch(ANTHROPIC_API, {
    method: 'POST',
    headers: { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({ model: 'claude-haiku-4-5-20251001', max_tokens: 512, system: systemPrompt, messages }),
  });
  if (!resp.ok) throw new Error(`Claude ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.content?.[0]?.text ?? '';
}

async function callGemini(systemPrompt, messages) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY not configured');
  const contents = messages.map(m => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));
  const resp = await fetch(`${GEMINI_API}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      system_instruction: { parts: [{ text: systemPrompt }] },
      contents,
      generationConfig: { maxOutputTokens: 512, temperature: 0.7 },
    }),
  });
  if (!resp.ok) throw new Error(`Gemini ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).end();

  const { message, context, history = [], uid, sessionId, provider = 'claude' } = req.body || {};
  if (!message) return res.status(400).json({ error: 'No message' });

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

  const messages = [
    ...history.slice(-8),
    { role: 'user', content: message },
  ];

  try {
    let reply = '';
    if (provider === 'gemini') {
      reply = await callGemini(systemPrompt, messages);
    } else {
      try {
        reply = await callClaude(systemPrompt, messages);
      } catch (claudeErr) {
        // Автоматический fallback на Gemini если Claude не отвечает
        console.warn('Claude failed, trying Gemini:', claudeErr.message);
        reply = await callGemini(systemPrompt, messages);
      }
    }

    // Save to Firestore (non-fatal)
    if (uid && sessionId && process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        const { initializeApp, cert, getApps } = await import('firebase-admin/app');
        const { getFirestore, FieldValue } = await import('firebase-admin/firestore');
        const sa = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        const app = getApps().length ? getApps()[0] : initializeApp({ credential: cert(sa) });
        const db = getFirestore(app);
        const ts = new Date();
        const ref = db.collection('users').doc(uid).collection('aiChats').doc(sessionId).collection('messages');
        await Promise.all([
          ref.add({ role: 'user', content: message, createdAt: ts }),
          ref.add({ role: 'assistant', content: reply, createdAt: ts }),
          db.collection('_aiStats').doc('global').set({ totalMessages: FieldValue.increment(1) }, { merge: true }),
        ]);
      } catch (_) {}
    }

    res.json({ reply, provider });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
