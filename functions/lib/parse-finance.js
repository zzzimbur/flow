// Парсер финансовых сообщений:
// "+5000 зп", "получил 3000 фриланс", "потратил 1500 продукты", "-800 кофе"
// Возвращает { amount, isIncome, category, note, date } или null.

const INCOME_WORDS = ['получил', 'получила', 'заработал', 'заработала', 'пришло', 'зачислили', 'доход', 'зп', 'зарплата', 'аванс', 'фриланс', 'подработка', 'бонус', 'премия', 'нашел', 'нашла', 'выиграл'];
const EXPENSE_WORDS = ['потратил', 'потратила', 'купил', 'купила', 'заплатил', 'заплатила', 'оплатил', 'оплатила', 'списали', 'расход', 'трата'];

// Число: 1500, 1 500, 1.5к, 1500р, $50
// (?:к|k) только если не продолжается буквой (чтобы не съесть «кофе»)
const AMOUNT_RE = /([+-]?\s*\d[\d\s]*(?:[.,]\d+)?)\s*(?:(?:к|k)(?![а-яёa-z])|тыс)?(?:руб|рублей|рубля|₽|р\b)?/i;

function parseAmount(raw, fullMatch) {
  const clean = raw.replace(/\s/g, '').replace(',', '.');
  // Определяем множитель из полного совпадения (fullMatch содержит суффикс «к»)
  const mult = /[\dр₽\s.,+-]*(?:к|k)(?![а-яёa-z])/i.test(fullMatch) ? 1000 : 1;
  const num = parseFloat(clean) * mult;
  return isNaN(num) ? null : num;
}

function resolveDate(tokens, now) {
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  for (const t of tokens) {
    if (t === 'вчера') { d.setDate(d.getDate() - 1); return d; }
    if (t === 'завтра') { d.setDate(d.getDate() + 1); return d; }
    if (t === 'сегодня') return d;
  }
  return d;
}

function parseFinanceMessage(text, now = new Date()) {
  const lower = text.trim().toLowerCase();

  // Определяем знак
  let isIncome = null;
  if (lower.startsWith('+')) isIncome = true;
  if (lower.startsWith('-')) isIncome = false;

  if (isIncome === null) {
    for (const w of INCOME_WORDS) {
      if (lower.includes(w)) { isIncome = true; break; }
    }
  }
  if (isIncome === null) {
    for (const w of EXPENSE_WORDS) {
      if (lower.includes(w)) { isIncome = false; break; }
    }
  }
  // Если нет явного знака/слова — нужна хотя бы сумма в тексте,
  // тогда считаем расходом по умолчанию (самый частый случай: «транспорт 800»)
  const match = lower.match(AMOUNT_RE);
  if (!match) return null;

  if (isIncome === null) {
    // Инфинитив в начале → это задача, а не запись о расходе
    // «перевести мише 5к» (инфинитив -ть/-сти/-зти) → task, «перевёл мише 5к» → finance
    const firstWord = lower.trim().split(/\s+/)[0];
    if (/ть$|сти$|зти$/.test(firstWord)) return null;

    const tentativeAmount = parseAmount(match[1], match[0]);
    // Число ≤ 23 + слово даты = скорее время (18:00), не сумма → отдаём task-парсеру
    if (tentativeAmount <= 23 && /(^|\s)(завтра|сегодня|послезавтра|вчера)(\s|$)/i.test(lower)) {
      return null;
    }
    isIncome = false; // «транспорт 800» → расход по умолчанию
  }

  const amount = parseAmount(match[1], match[0]);
  if (!amount || Math.abs(amount) < 1) return null;

  // Убираем из текста знак, ключевые слова и сумму → остаток = заметка/категория
  let rest = lower
    .replace(match[0], ' ')
    .replace(/^[+-]\s*/, '')
    .split(/\s+/)
    .filter((w) => ![...INCOME_WORDS, ...EXPENSE_WORDS, 'на', 'за', 'в', 'из', 'для', 'по'].includes(w))
    .join(' ')
    .trim();

  const tokens = rest.split(/\s+/);
  const date = resolveDate(tokens, now);
  rest = tokens.filter((t) => !['вчера', 'сегодня', 'завтра'].includes(t)).join(' ').trim();

  return {
    amount: Math.abs(amount),
    isIncome,
    category: rest || (isIncome ? 'Прочее' : 'Прочее'),
    note: rest,
    date,
  };
}

module.exports = { parseFinanceMessage };
