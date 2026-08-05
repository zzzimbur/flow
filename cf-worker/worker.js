/**
 * Flow AI — Cloudflare Worker
 * POST /          — Flow AI chat
 * GET  /auth/yandex          — начать Yandex OAuth
 * GET  /auth/yandex/callback — callback от Yandex
 * GET  /auth/telegram        — начать Telegram OAuth
 * GET  /auth/telegram/callback — callback от Telegram
 */

const WORKER_URL = 'https://flow-ai.prostozapaska.workers.dev';
const ANTHROPIC_API = 'https://api.anthropic.com/v1/messages';
const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
const GROQ_API = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_MODEL = 'llama-3.1-8b-instant';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ─── Firebase custom token (RSA JWT, без Admin SDK) ──────────────────────────

function b64url(data) {
  let str = '';
  if (typeof data === 'string') {
    str = data;
  } else {
    const bytes = new Uint8Array(data instanceof ArrayBuffer ? data : data.buffer);
    for (const b of bytes) str += String.fromCharCode(b);
  }
  return btoa(str).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

async function createFirebaseCustomToken(uid, env) {
  const email = env.FIREBASE_SA_EMAIL;
  const pem = (env.FIREBASE_SA_PRIVATE_KEY || '').replace(/\\n/g, '\n');
  if (!email || !pem) throw new Error('FIREBASE_SA_EMAIL / FIREBASE_SA_PRIVATE_KEY не заданы');

  const pemBody = pem.replace(/-----[A-Z ]+-----/g, '').replace(/\s/g, '');
  const keyBytes = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    'pkcs8', keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  );

  const now = Math.floor(Date.now() / 1000);
  const header  = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = b64url(JSON.stringify({
    iss: email, sub: email,
    aud: 'https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit',
    iat: now, exp: now + 3600,
    uid,
  }));

  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', key,
    new TextEncoder().encode(`${header}.${payload}`),
  );

  return `${header}.${payload}.${b64url(sig)}`;
}

// ─── Yandex OAuth ─────────────────────────────────────────────────────────────

async function handleYandexAuth(env) {
  const clientId = env.YANDEX_CLIENT_ID;
  if (!clientId) return new Response('YANDEX_CLIENT_ID не задан', { status: 500 });
  const url = new URL('https://oauth.yandex.ru/authorize');
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', clientId);
  url.searchParams.set('redirect_uri', `${WORKER_URL}/auth/yandex/callback`);
  return Response.redirect(url.toString(), 302);
}

async function handleYandexCallback(searchParams, env) {
  const code  = searchParams.get('code');
  const error = searchParams.get('error');
  if (error || !code) return Response.redirect('flowapp://oauth?error=yandex_denied', 302);

  const tokenResp = await fetch('https://oauth.yandex.ru/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code', code,
      client_id: env.YANDEX_CLIENT_ID,
      client_secret: env.YANDEX_CLIENT_SECRET,
      redirect_uri: `${WORKER_URL}/auth/yandex/callback`,
    }),
  });
  const tokenData = await tokenResp.json();
  if (tokenData.error) return Response.redirect('flowapp://oauth?error=yandex_token', 302);

  const userResp = await fetch('https://login.yandex.ru/info?format=json', {
    headers: { Authorization: `OAuth ${tokenData.access_token}` },
  });
  const userInfo = await userResp.json();

  try {
    const token = await createFirebaseCustomToken(`ya_${userInfo.id}`, env);
    return Response.redirect(`flowapp://oauth?token=${encodeURIComponent(token)}`, 302);
  } catch (e) {
    return Response.redirect(`flowapp://oauth?error=firebase_${encodeURIComponent(e.message)}`, 302);
  }
}

// ─── Telegram OAuth ───────────────────────────────────────────────────────────

async function handleTelegramAuth(env) {
  const botToken = env.TELEGRAM_BOT_TOKEN;
  if (!botToken) return new Response('TELEGRAM_BOT_TOKEN не задан', { status: 500 });
  const botId = botToken.split(':')[0];
  const returnTo = encodeURIComponent(`${WORKER_URL}/auth/telegram/callback`);
  return Response.redirect(
    `https://oauth.telegram.org/auth?bot_id=${botId}&scope=users_read&return_to=${returnTo}&origin=${WORKER_URL}`,
    302,
  );
}

async function handleTelegramCallback(searchParams, env) {
  const hash = searchParams.get('hash');
  if (!hash) return Response.redirect('flowapp://oauth?error=no_hash', 302);

  const params = Object.fromEntries(searchParams.entries());
  delete params.hash;

  // HMAC-SHA256: key = SHA256(botToken), data = sorted key=value joined by \n
  const enc = new TextEncoder();
  const botTokenHash = await crypto.subtle.digest('SHA-256', enc.encode(env.TELEGRAM_BOT_TOKEN));
  const hmacKey = await crypto.subtle.importKey(
    'raw', botTokenHash, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign'],
  );
  const dataCheck = Object.keys(params).sort().map(k => `${k}=${params[k]}`).join('\n');
  const sig = await crypto.subtle.sign('HMAC', hmacKey, enc.encode(dataCheck));
  const computed = Array.from(new Uint8Array(sig)).map(b => b.toString(16).padStart(2, '0')).join('');

  if (computed !== hash) return Response.redirect('flowapp://oauth?error=invalid_hash', 302);

  const authDate = parseInt(params.auth_date || '0', 10);
  if (Date.now() / 1000 - authDate > 600) return Response.redirect('flowapp://oauth?error=expired', 302);

  try {
    const token = await createFirebaseCustomToken(`tg_${params.id}`, env);
    return Response.redirect(`flowapp://oauth?token=${encodeURIComponent(token)}`, 302);
  } catch (e) {
    return Response.redirect(`flowapp://oauth?error=firebase_${encodeURIComponent(e.message)}`, 302);
  }
}

async function callClaude(apiKey, systemPrompt, messages) {
  const resp = await fetch(ANTHROPIC_API, {
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
  if (!resp.ok) throw new Error(`Claude ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.content?.[0]?.text ?? '';
}

async function callGroq(apiKey, systemPrompt, messages) {
  const resp = await fetch(GROQ_API, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: GROQ_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        ...messages,
      ],
      max_tokens: 512,
      temperature: 0.7,
    }),
  });
  if (!resp.ok) throw new Error(`Groq ${resp.status}: ${await resp.text()}`);
  const data = await resp.json();
  return data.choices?.[0]?.message?.content ?? '';
}

async function callGemini(apiKey, systemPrompt, messages) {
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

function buildSystemPrompt(ctx) {
  const expCats = ctx.expenseCategories;
  const expBreakdown = expCats && Object.keys(expCats).length > 0
    ? Object.entries(expCats)
        .sort((a, b) => b[1] - a[1])
        .map(([cat, amt]) => `${cat}: ${amt}₽`)
        .join(', ')
    : ctx.topExpenseCategories ?? '—';

  return `Ты Flow AI — персональный финансовый советник и аналитик по сменам.
Отвечаешь по-русски, конкретно и по делу. Используй эмодзи в меру.
На простые вопросы — кратко (2-4 предложения). На запросы анализа и разбора — структурированно, с разделами.

Данные пользователя (текущий месяц):
— Заработано на сменах: ${ctx.shiftEarnings ?? '—'} ₽ (${ctx.shiftCount ?? '—'} смен)
— Средняя смена: ${ctx.avgShift ?? '—'} ₽
— Доходы всего: ${ctx.totalIncome ?? '—'} ₽
— Расходы: ${ctx.totalExpense ?? '—'} ₽
— Баланс: ${ctx.balance ?? '—'} ₽
— Прогноз на следующий месяц: ${ctx.forecast ?? '—'} ₽
— Норма сбережений: ${ctx.savingsRate ?? '—'}%
— Расходы по категориям: ${expBreakdown}

При разборе расходов используй классификацию:
🔴 Обязательные — аренда, ЖКХ, продукты, транспорт, связь, кредиты
🟡 Полезные — образование, здоровье, спорт, рабочие инструменты
🟠 Эмоциональные — рестораны, развлечения, хобби (осознанные траты)
🔵 Импульсивные — спонтанные покупки, доставка без необходимости
⚫ Бесполезные — забытые подписки, дублирующиеся сервисы, невостребованное

Формат ответа на разбор расходов:
1. Распределение по 5 категориям с суммами
2. Топ трат — на что ушло больше всего
3. Что можно сократить — конкретные категории и примерные суммы
4. Прогноз экономии — сколько реально освободить в месяц
5. 3 главные финансовые ошибки месяца`;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    // ── OAuth routes (GET) ───────────────────────────────────────────
    if (request.method === 'GET') {
      if (path === '/auth/yandex')           return handleYandexAuth(env);
      if (path === '/auth/yandex/callback')  return handleYandexCallback(url.searchParams, env);
      if (path === '/auth/telegram')         return handleTelegramAuth(env);
      if (path === '/auth/telegram/callback') return handleTelegramCallback(url.searchParams, env);
      return new Response('Not found', { status: 404 });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: CORS_HEADERS });
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
        status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const { message, context, history = [], provider = 'claude' } = body;

    if (!message) {
      return new Response(JSON.stringify({ error: 'No message' }), {
        status: 400, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }

    const systemPrompt = buildSystemPrompt(context || {});
    const messages = [
      ...history.slice(-8),
      { role: 'user', content: message },
    ];

    try {
      let reply = '';
      let usedProvider = provider;

      // Порядок: Groq → Claude → Gemini
      const groqKey = env.GROQ_API_KEY;
      const claudeKey = env.ANTHROPIC_API_KEY;
      const geminiKey = env.GEMINI_API_KEY;

      if (!groqKey && !claudeKey && !geminiKey) {
        throw new Error('Ни один API ключ не настроен.');
      }

      const tryProviders = [
        groqKey   ? () => callGroq(groqKey, systemPrompt, messages).then(r => ({ r, p: 'groq' }))   : null,
        claudeKey ? () => callClaude(claudeKey, systemPrompt, messages).then(r => ({ r, p: 'claude' })) : null,
        geminiKey ? () => callGemini(geminiKey, systemPrompt, messages).then(r => ({ r, p: 'gemini' })) : null,
      ].filter(Boolean);

      let lastError;
      for (const fn of tryProviders) {
        try {
          const { r, p } = await fn();
          reply = r;
          usedProvider = p;
          break;
        } catch (e) {
          lastError = e;
        }
      }
      if (!reply) throw lastError;

      return new Response(JSON.stringify({ reply, provider: usedProvider }), {
        status: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    } catch (e) {
      return new Response(JSON.stringify({ error: e.message }), {
        status: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
      });
    }
  },
};
