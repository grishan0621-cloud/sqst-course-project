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

set -euo pipefail

HOST="${SONAR_HOST:-http://localhost:9000}"
TOKEN="${SONAR_TOKEN}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE_JSON="${SCRIPT_DIR}/quality-gate.json"

GATE_NAME="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['name'])" "$GATE_JSON")"

echo "Создаём Quality Gate: ${GATE_NAME}"

# С SonarQube 10.x параметр gateId в create_condition/select объявлен
# deprecated, а в актуальных CE (25/26.x) вызовы с gateId не работают.
# Работаем только с gateName и не полагаемся на id из ответа create.
# --data-urlencode — потому что в имени гейта есть пробелы.
curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create" \
  --data-urlencode "name=${GATE_NAME}" > /dev/null

python3 -c "
import json, sys
for c in json.load(open(sys.argv[1]))['conditions']:
    print('\t'.join(str(c[k]) for k in ('metric', 'op', 'error')))
" "$GATE_JSON" | while IFS=$'\t' read -r metric op error; do
  curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create_condition" \
    --data-urlencode "gateName=${GATE_NAME}" \
    -d "metric=${metric}&op=${op}&error=${error}" > /dev/null
  echo "  условие: ${metric} ${op} ${error}"
done

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/select" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "projectKey=vulnerable-app" > /dev/null

GATE_NAME_ENC="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$GATE_NAME")"
echo "Quality Gate «${GATE_NAME}» создан и назначен проекту vulnerable-app."
echo "Открой: ${HOST}/quality_gates/show/${GATE_NAME_ENC}"
