#!/usr/bin/env bash
# Создание кастомного Quality Gate через SonarQube API.
# Имя гейта и условия читаются из quality-gate.json — это единственный
# источник правды: пороги правим в JSON, скрипт подхватывает.
# Использование: SONAR_TOKEN=<token> bash setup-quality-gate.sh
#
# Про режимы SonarQube CE 25+: условия заданы в метриках Standard
# Experience (vulnerabilities, bugs, ...). По умолчанию CE работает в
# режиме MQR (Multi-Quality Rating), где UI показывает метрики
# software_quality_* — поэтому гейт в интерфейсе может выглядеть иначе.
# Переключение: Administration → Configuration → Mode.
#
# Обработка ошибок (issue #28): каждый вызов API проверяется по HTTP-коду;
# неверный/недостаточный токен, недоступный SonarQube или ошибка API дают
# rc!=0 с телом ответа, а не ложный «успех». Повторный запуск идемпотентен:
# «уже существует» — не ошибка. Нужен User Token (Project Analysis Token
# не имеет прав на /api/qualitygates/*).

set -euo pipefail

HOST="${SONAR_HOST:-http://localhost:9000}"
TOKEN="${SONAR_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "Ошибка: не задан SONAR_TOKEN. Запуск: SONAR_TOKEN=<token> bash setup-quality-gate.sh" >&2
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE_JSON="${SCRIPT_DIR}/quality-gate.json"

GATE_NAME="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['name'])" "$GATE_JSON")"

# Вызов API с проверкой HTTP-кода. Тело ответа кладёт в RESP_BODY,
# код — в RESP_CODE; возвращает 0 только на 2xx. curl без -f: код
# разбираем сами, чтобы показать тело ошибки (там текст от SonarQube).
RESP_BODY=""
RESP_CODE=""
api_call() {
  local out
  if ! out=$(curl -sS -u "${TOKEN}:" "$@" -w $'\n%{http_code}' 2>&1); then
    RESP_BODY="$out"
    RESP_CODE="000"
    return 1
  fi
  RESP_CODE="${out##*$'\n'}"
  RESP_BODY="${out%$'\n'*}"
  [ "$RESP_CODE" -ge 200 ] 2>/dev/null && [ "$RESP_CODE" -lt 300 ]
}

fail_api() {
  echo "Ошибка: $1 (HTTP ${RESP_CODE})." >&2
  [ -n "$RESP_BODY" ] && echo "Ответ сервера: ${RESP_BODY}" >&2
  echo "Проверь: SonarQube доступен на ${HOST}, SONAR_TOKEN — действующий User Token." >&2
  exit 1
}

echo "Создаём Quality Gate: ${GATE_NAME}"

# С SonarQube 10.x параметр gateId в create_condition/select объявлен
# deprecated, а в актуальных CE (25/26.x) вызовы с gateId не работают.
# Работаем только с gateName и не полагаемся на id из ответа create.
# --data-urlencode — потому что в имени гейта есть пробелы.
if api_call -X POST "${HOST}/api/qualitygates/create" \
    --data-urlencode "name=${GATE_NAME}"; then
  echo "  гейт создан"
elif printf '%s' "$RESP_BODY" | grep -qi "already"; then
  echo "  гейт уже существует — продолжаем (идемпотентный повтор)"
else
  fail_api "не удалось создать Quality Gate «${GATE_NAME}»"
fi

CONDITIONS="$(python3 -c "
import json, sys
for c in json.load(open(sys.argv[1]))['conditions']:
    print('\t'.join(str(c[k]) for k in ('metric', 'op', 'error')))
" "$GATE_JSON")"

while IFS=$'\t' read -r metric op error; do
  [ -n "$metric" ] || continue
  if api_call -X POST "${HOST}/api/qualitygates/create_condition" \
      --data-urlencode "gateName=${GATE_NAME}" \
      -d "metric=${metric}&op=${op}&error=${error}"; then
    echo "  условие: ${metric} ${op} ${error}"
  elif printf '%s' "$RESP_BODY" | grep -qi "already"; then
    echo "  условие уже есть: ${metric} ${op} ${error}"
  else
    fail_api "не удалось добавить условие ${metric} ${op} ${error}"
  fi
done <<EOF
$CONDITIONS
EOF

if ! api_call -X POST "${HOST}/api/qualitygates/select" \
    --data-urlencode "gateName=${GATE_NAME}" \
    -d "projectKey=vulnerable-app"; then
  fail_api "не удалось назначить гейт проекту vulnerable-app"
fi

# Финальная верификация: сообщаем об успехе только после подтверждения
# через API, что гейт существует.
if ! api_call -G "${HOST}/api/qualitygates/show" \
    --data-urlencode "name=${GATE_NAME}"; then
  fail_api "гейт не находится через /api/qualitygates/show после создания"
fi

GATE_NAME_ENC="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$GATE_NAME")"
echo "Quality Gate «${GATE_NAME}» создан и назначен проекту vulnerable-app."
echo "Открой: ${HOST}/quality_gates/show/${GATE_NAME_ENC}"
