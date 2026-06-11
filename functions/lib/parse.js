// Локальный (без AI) парсер сообщений вида:
//   "мак 14-19", "мак 14:30-19:00", "мак с 14 до 19", "завтра мак 9-18", "мак 12.06 14-19"
// Возвращает {name, date, startHour, startMinute, endHour, endMinute} или null.

const TIME_RANGE = /(?:с\s+)?(\d{1,2})(?:[:.](\d{2}))?\s*(?:-|–|—|до)\s*(\d{1,2})(?:[:.](\d{2}))?/i;
const EXPLICIT_DATE = /(\d{1,2})[.\/](\d{1,2})(?:[.\/](\d{2,4}))?/;

function resolveRelativeDate(word, now) {
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  switch (word) {
    case 'сегодня':
      return d;
    case 'завтра':
      d.setDate(d.getDate() + 1);
      return d;
    case 'послезавтра':
      d.setDate(d.getDate() + 2);
      return d;
    case 'вчера':
      d.setDate(d.getDate() - 1);
      return d;
    default:
      return null;
  }
}

function parseShiftMessage(text, now = new Date()) {
  let rest = text.trim().toLowerCase();

  const timeMatch = rest.match(TIME_RANGE);
  if (!timeMatch) return null;

  const startHour = parseInt(timeMatch[1], 10);
  const startMinute = timeMatch[2] ? parseInt(timeMatch[2], 10) : 0;
  const endHour = parseInt(timeMatch[3], 10);
  const endMinute = timeMatch[4] ? parseInt(timeMatch[4], 10) : 0;
  if (startHour > 23 || endHour > 23 || startMinute > 59 || endMinute > 59) return null;

  rest = (rest.slice(0, timeMatch.index) + ' ' + rest.slice(timeMatch.index + timeMatch[0].length)).trim();

  let date = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const dateMatch = rest.match(EXPLICIT_DATE);
  if (dateMatch) {
    const day = parseInt(dateMatch[1], 10);
    const month = parseInt(dateMatch[2], 10) - 1;
    let year = dateMatch[3] ? parseInt(dateMatch[3], 10) : now.getFullYear();
    if (year < 100) year += 2000;
    date = new Date(year, month, day);
    rest = (rest.slice(0, dateMatch.index) + ' ' + rest.slice(dateMatch.index + dateMatch[0].length)).trim();
  } else {
    for (const word of rest.split(/\s+/)) {
      const resolved = resolveRelativeDate(word, now);
      if (resolved) {
        date = resolved;
        rest = rest.replace(word, '').trim();
        break;
      }
    }
  }

  const name = rest.replace(/\s+/g, ' ').trim();
  if (!name) return null;

  return { name, date, startHour, startMinute, endHour, endMinute };
}

module.exports = { parseShiftMessage };
