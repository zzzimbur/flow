// Fallback-парсер свободного текста через YandexGPT.
// Требует секреты YANDEX_API_KEY и YANDEX_FOLDER_ID.

const COMPLETION_URL = 'https://llm.api.cloud.yandex.net/foundationModels/v1/completion';

const SYSTEM_PROMPT = `Ты — парсер сообщений о рабочих сменах. Пользователь пишет свободным текстом, когда и где он работает.
Верни ТОЛЬКО JSON без пояснений в формате:
{"name": "название места/смены", "date": "YYYY-MM-DD", "start": "HH:MM", "end": "HH:MM"}
Если в сообщении нет информации о смене, верни {"error": "not_a_shift"}.
Сегодняшняя дата: {TODAY}.`;

async function parseWithYandexGpt(text, { apiKey, folderId, now = new Date() }) {
  const today = now.toISOString().slice(0, 10);
  const response = await fetch(COMPLETION_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Api-Key ${apiKey}`,
    },
    body: JSON.stringify({
      modelUri: `gpt://${folderId}/yandexgpt-lite/latest`,
      completionOptions: { stream: false, temperature: 0, maxTokens: 200 },
      messages: [
        { role: 'system', text: SYSTEM_PROMPT.replace('{TODAY}', today) },
        { role: 'user', text },
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`YandexGPT HTTP ${response.status}: ${await response.text()}`);
  }

  const json = await response.json();
  const raw = json.result?.alternatives?.[0]?.message?.text ?? '';
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return null;

  let parsed;
  try {
    parsed = JSON.parse(jsonMatch[0]);
  } catch {
    return null;
  }
  if (parsed.error || !parsed.name || !parsed.date || !parsed.start || !parsed.end) return null;

  const [sh, sm] = parsed.start.split(':').map(Number);
  const [eh, em] = parsed.end.split(':').map(Number);
  const [y, m, d] = parsed.date.split('-').map(Number);
  if ([sh, sm, eh, em, y, m, d].some(Number.isNaN)) return null;

  return {
    name: String(parsed.name),
    date: new Date(y, m - 1, d),
    startHour: sh,
    startMinute: sm,
    endHour: eh,
    endMinute: em,
  };
}

module.exports = { parseWithYandexGpt };
