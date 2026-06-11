process.env.TZ = 'Europe/Moscow';

const { getAdmin } = require('../lib/firebase');
const { parseShiftMessage } = require('../lib/parse');
const { parseFinanceMessage } = require('../lib/parse-finance');
const { parseTaskMessage } = require('../lib/parse-task');
const { sendMessage, webhookSecret } = require('../lib/telegram');
const { loadUserContext, buildSystemPrompt, callClaude, loadHistory, saveTurn, hasAIPremium, activatePremium } = require('../lib/ai');

function db() { return getAdmin().firestore(); }
const fmtMoney = v => new Intl.NumberFormat('ru-RU', { maximumFractionDigits: 0 }).format(v);
const pad = n => String(n).padStart(2, '0');

// ─── Telegram helpers ────────────────────────────────────────────────────────

async function sendInlineKB(token, chatId, text, buttons) {
  await fetch(`https://api.telegram.org/bot${token}/sendMessage`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId, text, parse_mode: 'HTML',
      reply_markup: { inline_keyboard: buttons },
    }),
  });
}

async function answerCallback(token, callbackQueryId, text) {
  await fetch(`https://api.telegram.org/bot${token}/answerCallbackQuery`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ callback_query_id: callbackQueryId, text }),
  });
}

async function sendInvoice(token, chatId) {
  await fetch(`https://api.telegram.org/bot${token}/sendInvoice`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      chat_id: chatId,
      title: 'Flow AI — 1 месяц',
      description: 'Прогноз доходов · AI-советник · Сканирование чеков · Голосовой ввод',
      payload: 'flow_ai_1month',
      currency: 'XTR',          // Telegram Stars
      prices: [{ label: 'Flow AI (1 мес)', amount: 99 }],  // 99 Stars
      provider_token: '',        // пусто для Stars
    }),
  });
}

async function answerPreCheckout(token, preCheckoutQueryId, ok, errorMsg) {
  await fetch(`https://api.telegram.org/bot${token}/answerPreCheckoutQuery`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      pre_checkout_query_id: preCheckoutQueryId,
      ok,
      error_message: ok ? undefined : errorMsg,
    }),
  });
}

// ─── User helpers ─────────────────────────────────────────────────────────────

async function ensureTelegramUser(tgUser) {
  const admin = getAdmin();
  const mappingRef = db().collection('telegramUsers').doc(String(tgUser.id));
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
    uid, telegramId: tgUser.id, username: tgUser.username ?? null,
    createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
  });
  return uid;
}

async function getTgUidFromId(tgId) {
  const doc = await db().collection('telegramUsers').doc(String(tgId)).get();
  return doc.exists ? doc.data().uid : null;
}

async function findShiftTemplate(uid, name) {
  const snapshot = await db().collection('users').doc(uid).collection('templates').where('type', '==', 'shift').get();
  const needle = name.toLowerCase().trim();
  const templates = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  return templates.find(t => t.name.toLowerCase().trim() === needle)
    ?? templates.find(t => t.name.toLowerCase().includes(needle) || needle.includes(t.name.toLowerCase()))
    ?? null;
}

// ─── Create entities ──────────────────────────────────────────────────────────

async function createShift(uid, parsed, template) {
  const admin = getAdmin();
  const { date, startHour, startMinute, endHour, endMinute } = parsed;
  const startTime = new Date(date.getFullYear(), date.getMonth(), date.getDate(), startHour, startMinute);
  let endTime = new Date(date.getFullYear(), date.getMonth(), date.getDate(), endHour, endMinute);
  if (endTime <= startTime) endTime = new Date(endTime.getTime() + 86400000);
  const hours = (endTime - startTime) / 3600000;
  const t = template?.data ?? {};
  const shiftData = {
    name: template?.name ?? parsed.name, category: t.category ?? '',
    date: admin.firestore.Timestamp.fromDate(new Date(date.getFullYear(), date.getMonth(), date.getDate())),
    isAllDay: false,
    startTime: admin.firestore.Timestamp.fromDate(startTime),
    endTime: admin.firestore.Timestamp.fromDate(endTime),
    paymentType: t.paymentType ?? 'hourly', hourlyRate: t.hourlyRate ?? 0.0,
    paidTime: hours, bonus: t.bonus ?? 0.0, expenses: t.expenses ?? 0.0,
    shiftRate: t.shiftRate ?? 0.0, color: t.color ?? 0xFF8B7FF5,
    icon: t.icon ?? null, emoji: t.emoji ?? null, note: t.note ?? '',
    createdAt: admin.firestore.FieldValue.serverTimestamp(), source: 'telegram',
  };
  const ref = await db().collection('users').doc(uid).collection('shifts').add(shiftData);
  return { id: ref.id, shiftData, hours };
}

async function createTransaction(uid, parsed) {
  const admin = getAdmin();
  const data = {
    amount: Math.abs(parsed.amount), type: parsed.isIncome ? 'income' : 'expense',
    isIncome: parsed.isIncome, category: parsed.category || 'Прочее',
    note: parsed.note || '', date: admin.firestore.Timestamp.fromDate(parsed.date),
    createdAt: admin.firestore.FieldValue.serverTimestamp(), source: 'telegram',
  };
  const ref = await db().collection('users').doc(uid).collection('transactions').add(data);
  return { id: ref.id, data };
}

async function createTask(uid, parsed) {
  const admin = getAdmin();
  const data = {
    title: parsed.title,
    date: admin.firestore.Timestamp.fromDate(parsed.date),
    startTime: parsed.startTime ? admin.firestore.Timestamp.fromDate(parsed.startTime) : null,
    endTime: null, priority: parsed.priority || 'none', category: 'Личное',
    isDone: false, subtasks: [], hasReminder: false, repeatType: 'none',
    note: parsed.note || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(), source: 'telegram',
  };
  const ref = await db().collection('users').doc(uid).collection('tasks').add(data);
  return { id: ref.id, data };
}

// ─── Format replies ────────────────────────────────────────────────────────────

function formatShiftReply(parsed, template, created) {
  const { shiftData, hours } = created;
  const dateStr = parsed.date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', weekday: 'short' });
  const time = `${pad(parsed.startHour)}:${pad(parsed.startMinute)}–${pad(parsed.endHour)}:${pad(parsed.endMinute)}`;
  let earnings = null;
  if (shiftData.paymentType === 'hourly' && shiftData.hourlyRate > 0) earnings = shiftData.hourlyRate * hours + shiftData.bonus - shiftData.expenses;
  else if (shiftData.shiftRate > 0) earnings = shiftData.shiftRate + shiftData.bonus - shiftData.expenses;
  const lines = [
    `✅ Смена добавлена${template ? ' (по шаблону)' : ''}`,
    `<b>${shiftData.name}</b>`,
    `📅 ${dateStr}`,
    `🕐 ${time} (${hours.toFixed(hours % 1 ? 1 : 0)} ч)`,
  ];
  if (earnings != null) lines.push(`💰 ≈ ${fmtMoney(earnings)} ₽`);
  if (!template) lines.push('\n<i>Шаблон не найден — смена создана без ставки.</i>');
  return lines.join('\n');
}

function formatFinanceReply(parsed) {
  const sign = parsed.isIncome ? '+' : '−';
  const emoji = parsed.isIncome ? '💚' : '🔴';
  const dateStr = parsed.date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long' });
  return [`${emoji} Операция добавлена`, `${sign}${fmtMoney(parsed.amount)} ₽`, `📁 ${parsed.category || 'Прочее'}`, `📅 ${dateStr}`].join('\n');
}

function formatTaskReply(parsed) {
  const dateStr = parsed.date.toLocaleDateString('ru-RU', { day: 'numeric', month: 'long', weekday: 'short' });
  const priorityEmoji = { high: '🔴', medium: '🟡', low: '🟢', none: '' }[parsed.priority] ?? '';
  const timePart = parsed.startTime ? ` · ${pad(parsed.startTime.getHours())}:${pad(parsed.startTime.getMinutes())}` : '';
  return [`✅ Задача добавлена`, `<b>${parsed.title}</b>`, `📅 ${dateStr}${timePart}${priorityEmoji ? '  ' + priorityEmoji : ''}`].join('\n');
}

// ─── AI session ───────────────────────────────────────────────────────────────

// session = "day" key per user so history resets each day
function sessionId(tgId) {
  const d = new Date();
  return `tg_${tgId}_${d.getFullYear()}${d.getMonth()}${d.getDate()}`;
}

async function handleAIMessage(uid, tgId, userText, token, chatId) {
  const isPremium = await hasAIPremium(uid);
  if (!isPremium) {
    await sendInlineKB(token, chatId,
      '✦ Это функция <b>Flow AI</b>\n\nАI-советник, прогноз и советы по финансам доступны в премиум-подписке.',
      [[{ text: '⭐️ Подключить Flow AI — 99 Stars', callback_data: 'buy_premium' }]],
    );
    return;
  }

  // Show typing indicator
  await fetch(`https://api.telegram.org/bot${token}/sendChatAction`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
  });

  const sid = sessionId(tgId);
  const [ctx, history] = await Promise.all([loadUserContext(uid), loadHistory(uid, sid, 8)]);
  const sysPrompt = buildSystemPrompt(ctx);

  const messages = [
    ...history,
    { role: 'user', content: userText },
  ];

  const reply = await callClaude(sysPrompt, messages);

  await Promise.all([
    sendInlineKB(token, chatId, reply, [[
      { text: '👍', callback_data: `fb_good_${sid}` },
      { text: '👎', callback_data: `fb_bad_${sid}` },
    ]]),
    saveTurn(uid, sid, userText, reply, ctx),
  ]);
}

// ─── Commands ─────────────────────────────────────────────────────────────────

const HELP_TEXT = `<b>Flow — учёт смен, финансов и задач</b>

<b>Смены:</b>
• <code>мак 14-19</code>
• <code>завтра кафе 9:30-18:00</code>

<b>Финансы:</b>
• <code>получил 5000 зп</code>
• <code>потратил 800 продукты</code>
• <code>+3000 фриланс</code>  /  <code>-1500 кафе</code>

<b>Задачи:</b>
• <code>задача купить продукты</code>
• <code>напомни позвонить врачу завтра</code>

<b>Flow AI ✦</b>
• <code>/ai</code> — AI-советник (просто спроси)
• <code>/прогноз</code> — прогноз на следующий месяц
• <code>/отчёт</code> — отчёт за текущий месяц
• <code>/советы</code> — 3 совета по твоим данным
• <code>/premium</code> — подключить Flow AI

/link КОД — привязать аккаунт из приложения
/help — эта справка`;

async function handleForecast(uid, token, chatId) {
  const isPremium = await hasAIPremium(uid);
  if (!isPremium) {
    await sendInlineKB(token, chatId,
      '✦ Прогноз доступен в <b>Flow AI</b>',
      [[{ text: '⭐️ Подключить — 99 Stars', callback_data: 'buy_premium' }]],
    );
    return;
  }
  await fetch(`https://api.telegram.org/bot${token}/sendChatAction`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
  });
  const ctx = await loadUserContext(uid);
  const prompt = buildSystemPrompt(ctx);
  const reply = await callClaude(prompt, [{ role: 'user', content: 'Сделай прогноз доходов на следующий месяц. Объясни расчёт на основе моих данных.' }], 400);
  await sendMessage(token, chatId, `📈 <b>Прогноз на следующий месяц</b>\n\n${reply}`);
}

async function handleReport(uid, token, chatId) {
  const isPremium = await hasAIPremium(uid);
  if (!isPremium) {
    await sendInlineKB(token, chatId, '✦ Отчёт доступен в <b>Flow AI</b>', [[{ text: '⭐️ Подключить — 99 Stars', callback_data: 'buy_premium' }]]);
    return;
  }
  await fetch(`https://api.telegram.org/bot${token}/sendChatAction`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
  });
  const ctx = await loadUserContext(uid);
  const prompt = buildSystemPrompt(ctx);
  const reply = await callClaude(prompt, [{ role: 'user', content: 'Составь краткий финансовый отчёт за текущий месяц: смены, доходы, расходы, баланс, норма сбережений. Дай оценку результатам.' }], 500);
  await sendMessage(token, chatId, `📊 <b>Отчёт за текущий месяц</b>\n\n${reply}`);
}

async function handleTips(uid, token, chatId) {
  const isPremium = await hasAIPremium(uid);
  if (!isPremium) {
    await sendInlineKB(token, chatId, '✦ Советы доступны в <b>Flow AI</b>', [[{ text: '⭐️ Подключить — 99 Stars', callback_data: 'buy_premium' }]]);
    return;
  }
  await fetch(`https://api.telegram.org/bot${token}/sendChatAction`, {
    method: 'POST', headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ chat_id: chatId, action: 'typing' }),
  });
  const ctx = await loadUserContext(uid);
  const prompt = buildSystemPrompt(ctx);
  const reply = await callClaude(prompt, [{ role: 'user', content: 'Дай ровно 3 конкретных совета как улучшить финансовое положение. Каждый совет начинай с числа и пункта. Основывайся только на моих данных.' }], 450);
  await sendMessage(token, chatId, `💡 <b>3 совета по твоим данным</b>\n\n${reply}`);
}

async function handleLinkCommand(uid, tgUser, code, botToken, chatId) {
  const admin = getAdmin();
  const codeRef = db().collection('linkCodes').doc(code.toUpperCase());
  const snapshot = await codeRef.get();
  const data = snapshot.data();
  if (!snapshot.exists || data.expiresAt.toMillis() < Date.now()) {
    await sendMessage(botToken, chatId, '❌ Код не найден или истёк. Получи новый в приложении: Настройки → Привязать Telegram.');
    return;
  }
  await db().collection('telegramUsers').doc(String(tgUser.id)).set(
    { uid: data.uid, linkedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true },
  );
  await codeRef.delete();
  await sendMessage(botToken, chatId, '🔗 Готово! Telegram привязан к аккаунту Flow.');
}

// ─── Feedback handler ─────────────────────────────────────────────────────────

async function handleFeedback(uid, callbackData, token, callbackQueryId) {
  const [, rating, ...sidParts] = callbackData.split('_');
  const sid = sidParts.join('_');
  const isGood = rating === 'good';

  try {
    await db().collection('_aiStats').doc('feedback').set({
      [isGood ? 'thumbsUp' : 'thumbsDown']: getAdmin().firestore.FieldValue.increment(1),
    }, { merge: true });
    await db().collection('users').doc(uid).collection('aiChats').doc(sid).set({
      feedback: isGood ? 'good' : 'bad',
      feedbackAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  } catch (_) {}

  await answerCallback(token, callbackQueryId, isGood ? '👍 Спасибо!' : '👎 Учтём, постараемся лучше');
}

// ─── Main handler ─────────────────────────────────────────────────────────────

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') { res.status(405).end(); return; }

  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  if (!botToken) { res.status(500).send('no bot token'); return; }

  if (req.headers['x-telegram-bot-api-secret-token'] !== webhookSecret(botToken)) {
    res.status(403).send('forbidden'); return;
  }

  const update = req.body;
  res.status(200).send('ok'); // ack immediately

  // ── Callback queries (inline buttons) ──
  if (update?.callback_query) {
    const cq = update.callback_query;
    const tgId = cq.from.id;
    const chatId = cq.message?.chat?.id;
    const data = cq.data;

    try {
      const uid = await getTgUidFromId(tgId) ?? await ensureTelegramUser(cq.from);
      if (data === 'buy_premium') {
        await answerCallback(botToken, cq.id, '');
        await sendInvoice(botToken, chatId);
      } else if (data.startsWith('fb_')) {
        await handleFeedback(uid, data, botToken, cq.id);
      }
    } catch (e) { console.error('callback error:', e); }
    return;
  }

  // ── Pre-checkout query ──
  if (update?.pre_checkout_query) {
    const pcq = update.pre_checkout_query;
    await answerPreCheckout(botToken, pcq.id, true);
    return;
  }

  const message = update?.message;
  if (!message?.from || message.from.is_bot) return;

  // ── Successful payment ──
  if (message?.successful_payment) {
    try {
      const uid = await ensureTelegramUser(message.from);
      await activatePremium(uid, 1);
      await sendMessage(botToken, message.chat.id,
        '✦ <b>Flow AI активирован на 1 месяц!</b>\n\n' +
        'Теперь доступно:\n• /прогноз — прогноз доходов\n• /советы — AI-советы\n• /отчёт — месячный отчёт\n• Просто напиши любой вопрос — отвечу как AI-советник\n\nTакже все AI-функции открыты в приложении Flow 🚀'
      );
    } catch (e) { console.error('payment error:', e); }
    return;
  }

  if (!message?.text) return;

  const chatId = message.chat.id;
  const text = message.text.trim();

  try {
    const uid = await ensureTelegramUser(message.from);

    // ── Commands ──
    if (text.startsWith('/start') || text.startsWith('/help')) {
      await sendMessage(botToken, chatId, HELP_TEXT);
      return;
    }
    if (text.startsWith('/premium')) {
      await sendInvoice(botToken, chatId);
      return;
    }
    if (text.startsWith('/link')) {
      const code = text.split(/\s+/)[1];
      if (!code) await sendMessage(botToken, chatId, 'Использование: <code>/link КОД</code>');
      else await handleLinkCommand(uid, message.from, code, botToken, chatId);
      return;
    }
    if (text.startsWith('/прогноз') || text.startsWith('/forecast')) {
      await handleForecast(uid, botToken, chatId); return;
    }
    if (text.startsWith('/отчёт') || text.startsWith('/report')) {
      await handleReport(uid, botToken, chatId); return;
    }
    if (text.startsWith('/советы') || text.startsWith('/tips')) {
      await handleTips(uid, botToken, chatId); return;
    }
    if (text.startsWith('/ai') || text.startsWith('/советник')) {
      const question = text.replace(/^\/\w+\s*/, '').trim();
      if (!question) {
        await sendMessage(botToken, chatId, '✦ <b>Flow AI</b> — просто задай вопрос!\n\nНапример:\n• <i>Сколько я заработаю в следующем месяце?</i>\n• <i>Дай совет по расходам</i>\n• <i>Как мне работать эффективнее?</i>');
      } else {
        await handleAIMessage(uid, message.from.id, question, botToken, chatId);
      }
      return;
    }

    // ── Parse: смена → финансы → задача ──
    const shiftParsed = parseShiftMessage(text);
    if (shiftParsed) {
      const template = await findShiftTemplate(uid, shiftParsed.name);
      if (template) {
        const created = await createShift(uid, shiftParsed, template);
        await sendMessage(botToken, chatId, formatShiftReply(shiftParsed, template, created));
      } else {
        const date = new Date();
        const startTime = new Date(date.getFullYear(), date.getMonth(), date.getDate(), shiftParsed.startHour, shiftParsed.startMinute);
        const taskParsed = { title: shiftParsed.name.charAt(0).toUpperCase() + shiftParsed.name.slice(1), date, startTime, priority: 'none', note: null };
        await createTask(uid, taskParsed);
        await sendMessage(botToken, chatId, formatTaskReply(taskParsed) + '\n\n<i>Шаблон не найден — создано как событие.</i>');
      }
      return;
    }

    const financeParsed = parseFinanceMessage(text);
    if (financeParsed) {
      await createTransaction(uid, financeParsed);
      await sendMessage(botToken, chatId, formatFinanceReply(financeParsed));
      return;
    }

    const taskParsed = parseTaskMessage(text);
    if (taskParsed) {
      await createTask(uid, taskParsed);
      await sendMessage(botToken, chatId, formatTaskReply(taskParsed));
      return;
    }

    // ── Fallback: AI если ничего не распознано ──
    // Если сообщение похоже на вопрос или длиннее 3 слов — пробуем AI
    const isQuestion = /[?а-яё]{4,}/i.test(text) && text.split(' ').length > 2;
    if (isQuestion) {
      await handleAIMessage(uid, message.from.id, text, botToken, chatId);
    } else {
      await sendMessage(botToken, chatId, 'Не понял 🤔\n/help — что умею\n/ai — AI-советник');
    }
  } catch (e) {
    console.error('update error:', e);
    try { await sendMessage(botToken, chatId, '⚠️ Что-то пошло не так, попробуй ещё раз.'); } catch {}
  }
};
