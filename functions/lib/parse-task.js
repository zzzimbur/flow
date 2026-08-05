// Catch-all парсер задач.
// Вызывается только когда shift и finance не сработали.
// «купить хлеб завтра 18» → { title: 'Купить хлеб', date: завтра, startTime: 18:00 }
// «позвонить врачу» → { title: 'Позвонить врачу', date: сегодня }

// Слова-триггеры — не обязательны, но если есть — убираем из заголовка
const TRIGGERS = ['задача', 'задание', 'todo', 'напомни', 'напоминание', 'нужно', 'надо', 'не забыть', 'сделать'];

const PRIORITY_MAP = [
  ['high',   ['срочно', 'важно', 'критично']],
  ['medium', ['средний приоритет', 'желательно']],
  ['low',    ['не срочно', 'когда-нибудь']],
];

const RELATIVE_DATES = { сегодня: 0, завтра: 1, послезавтра: 2, вчера: -1 };
const EXPLICIT_DATE_RE = /\b(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?\b/;
// Время в конце: «18», «18:30», «в 18», «в 18:30»  — НЕ диапазон (без тире)
const TAIL_TIME_RE = /(?:\bв\s+)?(\d{1,2})(?::(\d{2}))?\s*$/i;

function stripTrigger(text) {
  const lower = text.toLowerCase();
  for (const t of [...TRIGGERS].sort((a, b) => b.length - a.length)) {
    if (lower.startsWith(t + ' ') || lower === t) {
      return text.slice(t.length).trim();
    }
  }
  return text;
}

function parseTaskMessage(text, now = new Date()) {
  let rest = stripTrigger(text.trim());
  if (!rest) return null;

  // Приоритет
  let priority = 'none';
  for (const [p, words] of PRIORITY_MAP) {
    for (const w of words) {
      if (rest.toLowerCase().includes(w)) {
        priority = p;
        rest = rest.replace(new RegExp(w, 'i'), '').trim();
        break;
      }
    }
    if (priority !== 'none') break;
  }

  // Время в конце (опционально). Проверяем ДО даты, чтобы не съесть часть даты.
  let startTime = null;
  const timeMatch = rest.match(TAIL_TIME_RE);
  if (timeMatch) {
    const h = parseInt(timeMatch[1]);
    const m = timeMatch[2] ? parseInt(timeMatch[2]) : 0;
    if (h <= 23 && m <= 59) {
      startTime = { hour: h, minute: m };
      rest = rest.slice(0, rest.length - timeMatch[0].length).trim();
    }
  }

  // Явная дата (12.06, 12/06)
  let date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const explicitDate = rest.match(EXPLICIT_DATE_RE);
  if (explicitDate) {
    const day = parseInt(explicitDate[1]);
    const month = parseInt(explicitDate[2]) - 1;
    let year = explicitDate[3] ? parseInt(explicitDate[3]) : now.getFullYear();
    if (year < 100) year += 2000;
    date = new Date(year, month, day);
    rest = rest.replace(explicitDate[0], '').trim();
  } else {
    // Относительная дата из слов
    const tokens = rest.split(/\s+/);
    const used = [];
    for (let i = 0; i < tokens.length; i++) {
      const t = tokens[i].toLowerCase();
      if (t in RELATIVE_DATES) {
        date = new Date(now.getFullYear(), now.getMonth(), now.getDate() + RELATIVE_DATES[t]);
        used.push(i);
        break;
      }
    }
    rest = tokens.filter((_, i) => !used.includes(i)).join(' ').trim();
  }

  if (!rest || rest.length < 2) return null;

  const title = rest.charAt(0).toUpperCase() + rest.slice(1);

  let startTimeFull = null;
  if (startTime) {
    startTimeFull = new Date(date.getFullYear(), date.getMonth(), date.getDate(), startTime.hour, startTime.minute);
  }

  return { title, date, startTime: startTimeFull, priority, note: null };
}

module.exports = { parseTaskMessage };
