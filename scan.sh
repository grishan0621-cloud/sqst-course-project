#!/usr/bin/env bash
# =============================================================================
# SonarScanner — запуск анализа через Docker
# Курс OTUS DevSecOps: SonarQube от А до Я
# Урок 2: Быстрый старт — установка и первое сканирование
# =============================================================================
# Использование:
#   ./lesson2/scan.sh                        # интерактивный ввод токена
#   SONAR_TOKEN=<token> ./lesson2/scan.sh    # токен через переменную окружения
#
# Предварительные условия:
#   - SonarQube запущен: docker compose up -d
#   - Создан проект и сгенерирован токен в Web UI
#   - Docker доступен в PATH
# =============================================================================

set -euo pipefail

# ---------- Настройки ---------------------------------------------------
# Дефолт SONAR_HOST зависит от платформы:
#   - Linux: сканер запускается с --network=host и делит сеть с хостом,
#     поэтому правильный адрес — http://localhost:9000 (тот же дефолт, что
#     в sonar-project.properties). host.docker.internal на Linux сам по
#     себе не резолвится — на этот случай ниже есть --add-host.
#   - macOS/Windows (Docker Desktop): host.docker.internal указывает на хост.
# Явно заданный SONAR_HOST всегда имеет приоритет:
#   SONAR_HOST=http://my-sonar:9000 ./scan.sh
case "$(uname -s)" in
  Darwin | MINGW* | MSYS* | CYGWIN*)
    DEFAULT_SONAR_HOST="http://host.docker.internal:9000"
    ;;
  *)
    DEFAULT_SONAR_HOST="http://localhost:9000"
    ;;
esac
SONAR_HOST="${SONAR_HOST:-$DEFAULT_SONAR_HOST}"
PROJECT_KEY="${PROJECT_KEY:-vulnerable-app}"
PROJECT_NAME="${PROJECT_NAME:-OTUS Vulnerable App (Учебный проект)}"
PROJECT_VERSION="${PROJECT_VERSION:-1.0-lesson15}"
SOURCES_DIR="backend,frontend"

# ---------- Получить токен ----------------------------------------------
if [[ -z "${SONAR_TOKEN:-}" ]]; then
  echo ""
  echo "🔑  Введите токен SonarQube (My Account → Security → Generate Token):"
  read -rs SONAR_TOKEN
  echo ""
fi

if [[ -z "$SONAR_TOKEN" ]]; then
  echo "❌  Токен не указан. Завершение." >&2
  exit 1
fi

# ---------- Запустить SonarScanner -------------------------------------
echo "🚀  Запускаю анализ проекта '$PROJECT_KEY' ..."
echo "    Сервер: $SONAR_HOST"
echo ""

# --add-host делает host.docker.internal рабочим и на Linux (Docker 20.10+),
# если пользователь переопределил SONAR_HOST на этот алиас.
docker run --rm \
  --network=host \
  --add-host=host.docker.internal:host-gateway \
  -v "$(pwd):/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey="$PROJECT_KEY" \
  -Dsonar.projectName="$PROJECT_NAME" \
  -Dsonar.projectVersion="$PROJECT_VERSION" \
  -Dsonar.sources="$SOURCES_DIR" \
  -Dsonar.sourceEncoding=UTF-8 \
  -Dsonar.exclusions="**/__pycache__/**,**/*.pyc" \
  -Dsonar.host.url="$SONAR_HOST" \
  -Dsonar.token="$SONAR_TOKEN"

# Ссылку для браузера показываем через localhost: host.docker.internal —
# алиас только для контейнеров, на хосте он не резолвится.
WEB_URL="${SONAR_HOST//host.docker.internal/localhost}"
echo ""
echo "✅  Анализ завершён. Открой результаты в Web UI:"
echo "    ${WEB_URL}/dashboard?id=${PROJECT_KEY}"
