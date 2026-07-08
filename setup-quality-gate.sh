#!/usr/bin/env bash
# Создание кастомного Quality Gate через SonarQube API
# Использование: SONAR_TOKEN=<token> bash setup-quality-gate.sh

set -euo pipefail

HOST="${SONAR_HOST:-http://localhost:9000}"
TOKEN="${SONAR_TOKEN}"
GATE_NAME="OTUS Strict Gate"

echo "Создаём Quality Gate: ${GATE_NAME}"

# С SonarQube 10.x параметр gateId в create_condition/select объявлен
# deprecated, а в актуальных CE (25/26.x) вызовы с gateId не работают.
# Работаем только с gateName и не полагаемся на id из ответа create.
# --data-urlencode — потому что в имени гейта есть пробелы.
curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create" \
  --data-urlencode "name=${GATE_NAME}" > /dev/null

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create_condition" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "metric=vulnerabilities&op=GT&error=0" > /dev/null

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create_condition" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "metric=bugs&op=GT&error=2" > /dev/null

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create_condition" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "metric=new_vulnerabilities&op=GT&error=0" > /dev/null

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/create_condition" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "metric=new_bugs&op=GT&error=0" > /dev/null

curl -s -u "${TOKEN}:" -X POST "${HOST}/api/qualitygates/select" \
  --data-urlencode "gateName=${GATE_NAME}" \
  -d "projectKey=vulnerable-app" > /dev/null

echo "Quality Gate «${GATE_NAME}» создан и назначен проекту vulnerable-app."
echo "Открой: ${HOST}/quality_gates/show/OTUS%20Strict%20Gate"
