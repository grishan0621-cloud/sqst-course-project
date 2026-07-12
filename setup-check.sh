#!/bin/bash
# =============================================================================
# setup-check.sh — Проверка готовности рабочего окружения
# Курс OTUS DevSecOps: SonarQube от А до Я
# =============================================================================
# Использование: bash setup-check.sh
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SonarQube Course — Проверка окружения                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

check() {
    local desc="$1"
    local cmd="$2"
    local expected_min_version="$3"

    if eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $desc"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $desc"
        ((FAIL++))
    fi
}

warn_check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $desc"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠${NC} $desc (рекомендуется, но не обязательно)"
        ((WARN++))
    fi
}

# --- Docker ---
echo -e "${BLUE}[1] Docker${NC}"
check "docker установлен" "docker --version"
check "docker daemon запущен" "docker info"
check "docker compose доступен" "docker compose version"
echo ""

# --- Системные ресурсы ---
echo -e "${BLUE}[2] Системные ресурсы${NC}"

# Проверка RAM (нужно минимум 4GB, рекомендуется 8GB)
if command -v free &>/dev/null; then
    TOTAL_MEM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM_GB" -ge 8 ]; then
        echo -e "  ${GREEN}✓${NC} RAM: ${TOTAL_MEM_GB}GB (достаточно)"
        ((PASS++))
    elif [ "$TOTAL_MEM_GB" -ge 4 ]; then
        echo -e "  ${YELLOW}⚠${NC} RAM: ${TOTAL_MEM_GB}GB (минимум, рекомендуется 8GB)"
        ((WARN++))
    else
        echo -e "  ${RED}✗${NC} RAM: ${TOTAL_MEM_GB}GB (недостаточно, нужно минимум 4GB)"
        ((FAIL++))
    fi
elif command -v sysctl &>/dev/null; then
    # macOS
    TOTAL_MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    TOTAL_MEM_GB=$((TOTAL_MEM_BYTES / 1024 / 1024 / 1024))
    if [ "$TOTAL_MEM_GB" -ge 8 ]; then
        echo -e "  ${GREEN}✓${NC} RAM: ${TOTAL_MEM_GB}GB (достаточно)"
        ((PASS++))
    else
        echo -e "  ${YELLOW}⚠${NC} RAM: ${TOTAL_MEM_GB}GB (рекомендуется 8GB)"
        ((WARN++))
    fi
fi

# vm.max_map_count (Linux, нужно для Elasticsearch внутри SonarQube)
if [ -f /proc/sys/vm/max_map_count ]; then
    MAX_MAP=$(cat /proc/sys/vm/max_map_count)
    if [ "$MAX_MAP" -ge 524288 ]; then
        echo -e "  ${GREEN}✓${NC} vm.max_map_count=${MAX_MAP} (достаточно)"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} vm.max_map_count=${MAX_MAP} (нужно >= 524288)"
        echo -e "       Исправление: sudo sysctl -w vm.max_map_count=524288"
        ((FAIL++))
    fi
fi

# Проверка свободного места (нужно минимум 5GB)
FREE_GB=$(df -BG . | awk 'NR==2 {gsub("G",""); print $4}')
if [ "$FREE_GB" -ge 10 ]; then
    echo -e "  ${GREEN}✓${NC} Свободное место: ${FREE_GB}GB"
    ((PASS++))
elif [ "$FREE_GB" -ge 5 ]; then
    echo -e "  ${YELLOW}⚠${NC} Свободное место: ${FREE_GB}GB (рекомендуется 10GB)"
    ((WARN++))
else
    echo -e "  ${RED}✗${NC} Свободное место: ${FREE_GB}GB (нужно минимум 5GB)"
    ((FAIL++))
fi
echo ""

# --- Сеть ---
echo -e "${BLUE}[3] Сеть${NC}"
check "порт 9000 свободен" "! nc -z localhost 9000 2>/dev/null || docker ps | grep -q sonarqube"
warn_check "доступ к docker.io" "docker pull hello-world 2>&1 | grep -q 'Hello from Docker\|already'"
echo ""

# --- Инструменты (опционально) ---
echo -e "${BLUE}[4] Дополнительные инструменты${NC}"
warn_check "git установлен" "git --version"
warn_check "curl установлен" "curl --version"
warn_check "python3 установлен" "python3 --version"
warn_check "pip3 установлен" "pip3 --version"
echo ""

# --- Проверка файлов проекта ---
echo -e "${BLUE}[5] Файлы проекта${NC}"
check "docker-compose.yml существует" "test -f docker-compose.yml"
check "sonar-project.properties существует" "test -f sonar-project.properties"
check "backend/app.py существует" "test -f backend/app.py"
echo ""

# --- Итог ---
echo -e "${BLUE}══════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS + FAIL + WARN))
echo -e "  Итог: ${GREEN}${PASS} ✓${NC}  ${RED}${FAIL} ✗${NC}  ${YELLOW}${WARN} ⚠${NC}  (всего проверок: $TOTAL)"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}Окружение не готово.${NC} Устраните ошибки выше и запустите скрипт снова."
    echo ""
    echo -e "  ${YELLOW}Частые решения:${NC}"
    echo "    • vm.max_map_count:  sudo sysctl -w vm.max_map_count=524288"
    echo "    • Docker daemon:     sudo systemctl start docker"
    echo "    • Место на диске:    docker system prune -af"
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo -e "  ${YELLOW}Окружение готово с предупреждениями.${NC} Продолжайте с осторожностью."
    exit 0
else
    echo -e "  ${GREEN}Окружение полностью готово!${NC} Запустите: docker compose up -d"
    exit 0
fi
