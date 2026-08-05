# Flow Bot — Vercel

## Эндпоинты
- `POST /api/webhook` — Telegram вебхук (бот)
- `POST /api/auth` — mini app: initData → Firebase custom token
- `POST /api/link-code` — приложение: выдать код привязки Telegram (нужен Firebase ID token)

## Деплой (10 минут)

### 1. Получить токен бота
@BotFather → `/newbot` → сохрани токен.

### 2. Service account Firebase
[Firebase Console](https://console.firebase.google.com/project/flowapp-25488/settings/serviceaccounts/adminsdk)
→ «Создать новый закрытый ключ» → скачать JSON → base64:
```bash
base64 -i ~/Downloads/flowapp-*.json | tr -d '\n'
```
Сохрани результат — это `FIREBASE_SERVICE_ACCOUNT`.

### 3. Задеплоить на Vercel
```bash
cd functions
npm i -g vercel   # один раз
vercel            # следовать инструкции, root = functions/
```
После деплоя Vercel покажет URL, например: `https://flow-bot.vercel.app`

### 4. Добавить переменные окружения в Vercel
В Vercel Dashboard → Settings → Environment Variables:
| Key | Value |
|-----|-------|
| `TELEGRAM_BOT_TOKEN` | токен от BotFather |
| `FIREBASE_SERVICE_ACCOUNT` | base64 из шага 2 |
| `YANDEX_API_KEY` | (опционально, для свободного текста) |
| `YANDEX_FOLDER_ID` | (опционально) |

### 5. Привязать вебхук
```bash
./setup-webhook.sh <BOT_TOKEN> <VERCEL_URL>
# например: ./setup-webhook.sh 123:ABC https://flow-bot.vercel.app
```

### 6. Mini App
В @BotFather → Bot Settings → Menu Button → URL:
`https://flow-bot.vercel.app/miniapp` (или используй отдельный хостинг для `miniapp/`)

---
Парсинг: сначала бесплатный regex (`lib/parse.js`), при неудаче — YandexGPT (`lib/yandexgpt.js`).
Если `YANDEX_API_KEY` не задан — работает только regex (достаточно для «мак 14-19»).
