export const config = { maxDuration: 30 };

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).end();

  const { imageBase64, mediaType } = req.body || {};
  if (!imageBase64) return res.status(400).json({ error: 'No image' });

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return res.status(500).json({ error: 'ANTHROPIC_API_KEY not configured' });

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
        max_tokens: 256,
        messages: [{
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: mediaType || 'image/jpeg',
                data: imageBase64,
              },
            },
            {
              type: 'text',
              text: `Извлеки данные из этого чека/квитанции.
Ответь ТОЛЬКО JSON без пояснений:
{"amount": <число>, "name": "<название магазина>", "category": "<одно из: Продукты/Кафе/Транспорт/Здоровье/Одежда/Другое>", "date": "<YYYY-MM-DD или null>"}
Если поле не читается — null.`,
            },
          ],
        }],
      }),
    });

    const data = await response.json();
    const text = data.content?.[0]?.text ?? '{}';
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return res.json({ amount: null, name: null, category: 'Другое', date: null });
    const parsed = JSON.parse(match[0]);
    res.json(parsed);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
