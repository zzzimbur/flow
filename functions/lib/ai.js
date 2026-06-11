// Shared AI helper used by webhook + advice endpoint
const { getAdmin } = require('./firebase');

const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages';
const MODEL = 'claude-haiku-4-5-20251001';

function db() { return getAdmin().firestore(); }

/** Load user's financial context for AI */
async function loadUserContext(uid) {
  const admin = getAdmin();
  const now = new Date();
  const ms = new Date(now.getFullYear(), now.getMonth(), 1);
  const me = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const ms3 = new Date(now.getFullYear(), now.getMonth() - 3, 1);

  const [shiftSnap, txSnap, taskSnap] = await Promise.all([
    db().collection('users').doc(uid).collection('shifts')
      .where('date', '>=', admin.firestore.Timestamp.fromDate(ms3))
      .where('date', '<', admin.firestore.Timestamp.fromDate(me))
      .orderBy('date', 'desc').limit(60).get(),
    db().collection('users').doc(uid).collection('transactions')
      .where('date', '>=', admin.firestore.Timestamp.fromDate(ms))
      .where('date', '<', admin.firestore.Timestamp.fromDate(me))
      .orderBy('date', 'desc').limit(80).get(),
    db().collection('users').doc(uid).collection('tasks')
      .where('isDone', '==', false).limit(20).get(),
  ]);

  // Month earnings
  let shiftEarn = 0, shiftCount = 0, totalHours = 0;
  const shiftsByMonth = {};
  for (const d of shiftSnap.docs) {
    const s = d.data();
    const d2 = s.date.toDate();
    const mk = `${d2.getFullYear()}-${d2.getMonth()}`;
    const st = s.startTime.toDate(), en = s.endTime.toDate();
    const ph = s.paidTime > 0 ? s.paidTime : (en - st) / 3600000;
    const e = s.paymentType === 'hourly' ? (s.hourlyRate || 0) * ph : (s.shiftRate || 0);
    const earn = e + (s.bonus || 0) - (s.expenses || 0);
    if (!shiftsByMonth[mk]) shiftsByMonth[mk] = { earn: 0, count: 0 };
    shiftsByMonth[mk].earn += earn;
    shiftsByMonth[mk].count++;
    const curMk = `${now.getFullYear()}-${now.getMonth()}`;
    if (mk === curMk) { shiftEarn += earn; shiftCount++; totalHours += ph; }
  }

  // Forecast (avg last 3 months)
  const months = Object.entries(shiftsByMonth).filter(([k]) => k !== `${now.getFullYear()}-${now.getMonth()}`);
  const forecast = months.length > 0 ? months.reduce((a, [, v]) => a + v.earn, 0) / months.length : shiftEarn;

  // Transactions
  let inc = 0, exp = 0;
  const expByCat = {};
  for (const d of txSnap.docs) {
    const t = d.data();
    const amt = Math.abs(t.amount || 0);
    if (t.type === 'income' || t.isIncome) {
      inc += amt;
    } else {
      exp += amt;
      const cat = t.category || 'Другое';
      expByCat[cat] = (expByCat[cat] || 0) + amt;
    }
  }
  const topExp = Object.entries(expByCat).sort((a, b) => b[1] - a[1]).slice(0, 3)
    .map(([k, v]) => `${k}: ${Math.round(v)}₽`).join(', ');

  // Active tasks
  const activeTasks = taskSnap.docs.map(d => d.data().title || d.data().name || '').filter(Boolean).slice(0, 5);

  return {
    shiftEarnings: Math.round(shiftEarn),
    shiftCount,
    totalHours: Math.round(totalHours),
    avgShift: shiftCount > 0 ? Math.round(shiftEarn / shiftCount) : 0,
    totalIncome: Math.round(inc + shiftEarn),
    totalExpense: Math.round(exp),
    balance: Math.round(inc + shiftEarn - exp),
    forecast: Math.round(forecast),
    topExpenseCategories: topExp || 'нет данных',
    activeTasks: activeTasks.join(', ') || 'нет',
    savingsRate: (inc + shiftEarn) > 0 ? Math.round((inc + shiftEarn - exp) / (inc + shiftEarn) * 100) : 0,
  };
}

function buildSystemPrompt(ctx) {
  return `Ты Flow AI — персональный финансовый советник и аналитик по сменам.
Отвечаешь по-русски, кратко (2-4 предложения), конкретно и по делу.
Используй эмодзи в меру. Считай на основе реальных данных ниже.

Данные пользователя (текущий месяц):
— Заработано на сменах: ${ctx.shiftEarnings} ₽ (${ctx.shiftCount} смен, ${ctx.totalHours}ч)
— Средняя смена: ${ctx.avgShift} ₽
— Доходы всего: ${ctx.totalIncome} ₽
— Расходы: ${ctx.totalExpense} ₽
— Баланс: ${ctx.balance} ₽
— Норма сбережений: ${ctx.savingsRate}%
— Прогноз на следующий месяц: ${ctx.forecast} ₽
— Топ расходы: ${ctx.topExpenseCategories}
— Активные задачи: ${ctx.activeTasks}

Если спрашивают о прогнозе — используй число ${ctx.forecast} ₽.
Если данных нет — скажи прямо и предложи добавить данные через приложение или бота.`;
}

/** Call Anthropic API */
async function callClaude(systemPrompt, messages, maxTokens = 512) {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) throw new Error('ANTHROPIC_API_KEY not set');

  const resp = await fetch(ANTHROPIC_API, {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({ model: MODEL, max_tokens: maxTokens, system: systemPrompt, messages }),
  });

  if (!resp.ok) throw new Error(`Anthropic ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.content?.[0]?.text ?? '';
}

/** Load last N conversation turns from Firestore */
async function loadHistory(uid, sessionId, limit = 8) {
  const snap = await db()
    .collection('users').doc(uid)
    .collection('aiChats').doc(sessionId)
    .collection('messages')
    .orderBy('createdAt', 'desc').limit(limit).get();
  return snap.docs.reverse().map(d => ({ role: d.data().role, content: d.data().content }));
}

/** Save a turn (user + assistant) to Firestore */
async function saveTurn(uid, sessionId, userMsg, aiReply, ctx) {
  const admin = getAdmin();
  const ref = db().collection('users').doc(uid).collection('aiChats').doc(sessionId).collection('messages');
  const batch = db().batch();
  const ts = admin.firestore.FieldValue.serverTimestamp();

  batch.set(ref.doc(), { role: 'user', content: userMsg, createdAt: ts });
  batch.set(ref.doc(), { role: 'assistant', content: aiReply, createdAt: ts });

  // Analytics: increment counters
  const statsRef = db().collection('_aiStats').doc('global');
  batch.set(statsRef, {
    totalMessages: admin.firestore.FieldValue.increment(1),
    lastUpdated: ts,
  }, { merge: true });

  // Per-user stats
  const userStatsRef = db().collection('_aiStats').doc(uid);
  batch.set(userStatsRef, {
    messageCount: admin.firestore.FieldValue.increment(1),
    lastMessage: ts,
    lastContext: ctx,
  }, { merge: true });

  await batch.commit();
}

/** Check if user has AI premium */
async function hasAIPremium(uid) {
  try {
    const doc = await db().collection('users').doc(uid).get();
    if (!doc.exists) return false;
    const data = doc.data();
    if (data.isPremium) {
      const expiry = data.premiumExpiry?.toDate?.();
      if (!expiry || expiry > new Date()) return true;
    }
    return false;
  } catch { return false; }
}

/** Activate premium for user */
async function activatePremium(uid, months = 1) {
  const admin = getAdmin();
  const expiry = new Date();
  expiry.setMonth(expiry.getMonth() + months);
  await db().collection('users').doc(uid).set({
    isPremium: true,
    premiumExpiry: admin.firestore.Timestamp.fromDate(expiry),
    premiumActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
    premiumSource: 'telegram_stars',
  }, { merge: true });
}

module.exports = { loadUserContext, buildSystemPrompt, callClaude, loadHistory, saveTurn, hasAIPremium, activatePremium };
