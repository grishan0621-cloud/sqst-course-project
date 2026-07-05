# OTUS SonarQube Course — Учебный проект

Репозиторий учебного проекта курса **«Безопасный код с SonarQube (Community Edition)»** (OTUS).

Проект прогрессивно развивается от урока к уроку: на уроке 1 это простое Flask-приложение с 5 уязвимостями, к уроку 15 — полноценная DevSecOps-платформа с многомодульной архитектурой, CI/CD-пайплайном и многоуровневым SAST.

## Структура проекта (финальная, урок 15)

```
.
├── docker-compose.yml              # SonarQube CE + PostgreSQL (dev-окружение)
├── sonar-project.properties        # Параметры анализа для sonar-scanner
├── scan.sh                         # Запуск sonar-scanner из CLI
├── setup-check.sh                  # Проверка готовности окружения
├── setup-quality-gate.sh           # Настройка кастомного Quality Gate через API
├── quality-gate.json               # Определение OTUS Strict Gate (пороги качества)
├── Jenkinsfile                     # CI/CD-пайплайн для Jenkins
├── fp-analysis.md                  # Документация по False Positive анализу
├── hotspot-review.md               # Аудит Security Hotspot-ов
├── access-policy.md                # Ролевая модель и hardening SonarQube
│
├── vulnerable-app/                 # Учебное Flask-приложение (намеренно уязвимое)
│   ├── app.py                      # Основной модуль — SQL Injection, XSS, Path Traversal и др.
│   ├── utils.py                    # Вспомогательные функции с уязвимостями
│   └── requirements.txt            # Зависимости с известными CVE (для Dependency-Check)
│
├── backend/                        # Backend-модуль (многомодульная структура, урок 11+)
│   ├── app.py                      # Flask-приложение
│   ├── utils.py                    # Утилиты
│   ├── requirements.txt            # Python-зависимости
│   └── sonar-project.properties    # Параметры анализа backend-модуля
│
├── frontend/                       # Frontend-модуль (JavaScript, урок 8+)
│   ├── app.js                      # Node.js-приложение с типичными JS-уязвимостями
│   └── sonar-project.properties    # Параметры анализа frontend-модуля
│
├── performance/                    # Конфигурации для production (урок 13+)
│   ├── docker-compose.prod.yml     # Production-конфигурация Docker Compose
│   ├── postgresql.conf             # Оптимизация PostgreSQL для SonarQube
│   └── performance-baseline.md     # Базовые метрики производительности
│
├── audit/                          # Материалы аудита (урок 14+)
│   └── configuration-audit.md      # Аудит конфигурации: антипаттерны и их исправление
│
├── comparison/                     # Сравнение SAST-инструментов (урок 15)
│   └── sast-comparison.md          # Semgrep, Checkmarx, CodeQL vs SonarQube
│
├── .sonarlint/                     # Конфигурация SonarLint для IDE (урок 10+)
│   └── settings.json
│
└── .gitlab/                        # GitLab-интеграция (урок 10+)
    └── merge_request_templates/
        └── Default.md              # MR-шаблон с чеклистом качества кода
```

## Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/ignatenkofi/sqst-vulnerable-app.git
cd sqst-vulnerable-app

# 2. Проверить готовность окружения
bash setup-check.sh

# 3. Запустить SonarQube
docker compose up -d

# 4. Открыть http://localhost:9000
# Логин: admin / admin (смените пароль при первом входе)

# 5. Запустить анализ
bash scan.sh
```

## Описание компонентов

### vulnerable-app/

**Учебное Flask-приложение**, намеренно содержащее уязвимости для демонстрации возможностей SonarQube. Включает 5+ типов уязвимостей: SQL Injection, XSS, Path Traversal, использование eval(), хардкод секретов. Файл `requirements.txt` содержит зависимости с известными CVE для демонстрации OWASP Dependency-Check.

### backend/ и frontend/

**Многомодульная структура** (с урока 11). Демонстрирует раздельный анализ модулей с индивидуальными `sonar-project.properties`. Backend — Python/Flask, Frontend — JavaScript/Node.js.

### performance/

**Конфигурации для production-окружения** (с урока 13). Включает оптимизированный Docker Compose с настройками JVM, тюнинг PostgreSQL и базовые метрики для контроля деградации производительности.

### audit/

**Аудит конфигурации** (с урока 14). Документация типичных антипаттернов (пропуск coverage, слишком мягкий Quality Gate, игнорирование Security Hotspot) и рекомендации по их устранению.

### comparison/

**Сравнение SAST-инструментов** (урок 15). Анализ альтернатив SonarQube (Semgrep, Checkmarx, CodeQL) с рекомендациями по построению многоуровневого SAST-пайплайна.

### Shell-скрипты

| Скрипт | Описание |
|--------|----------|
| `setup-check.sh` | Проверяет наличие Docker, Docker Compose, Java, sonar-scanner. Выводит статус готовности |
| `scan.sh` | Запускает sonar-scanner с параметрами из `sonar-project.properties` |
| `setup-quality-gate.sh` | Создаёт кастомный Quality Gate «OTUS Strict Gate» через REST API SonarQube |

### CI/CD

- `Jenkinsfile` — многоступенчатый пайплайн: checkout → scan → quality gate check
- Предусмотрена интеграция с GitLab CI (`.gitlab-ci.yml` в отдельных уроках)

## Эволюция проекта по урокам

| Урок | Тема | Что добавлено |
|------|------|---------------|
| 1 | Введение | `docker-compose.yml`, `app.py` с 5 уязвимостями |
| 2 | Быстрый старт | `scan.sh`, `utils.py` |
| 3 | SAST & OWASP | Маппинг уязвимостей на OWASP Top 10 |
| 4 | CI/CD | `Jenkinsfile`, `.gitlab-ci.yml`, `.github/workflows/sonarqube-scan.yml` |
| 5 | Quality Gate | `quality-gate.json`, `setup-quality-gate.sh` |
| 6 | False Positive | `fp-analysis.md`, NOSONAR с обоснованиями |
| 7 | Security Hotspots | `hotspot-review.md` |
| 8 | Мультиязычность | `frontend/app.js` |
| 9 | Зависимости | `requirements.txt` с CVE, OWASP Dep-Check |
| 10 | Код-ревью | `.sonarlint/`, MR-шаблон с чеклистом |
| 11 | Монорепозитории | `backend/` с отдельным `sonar-project.properties` |
| 12 | Безопасность | `access-policy.md` |
| 13 | Производительность | `performance/` (JVM, PostgreSQL, baseline) |
| 14 | Best practices | `audit/configuration-audit.md` |
| 15 | Альтернативы | `comparison/sast-comparison.md`, `.semgrep.yml` |

## Требования

- Docker Desktop (Windows/macOS) или Docker Engine + Docker Compose (Linux)
- RAM: минимум 4 ГБ, рекомендуется 8 ГБ
- Диск: минимум 5 ГБ свободного места
- Порт 9000 должен быть свободен
- sonar-scanner CLI (для локального анализа)
- Node.js (для frontend-анализа)
- Python 3.8+ (для vulnerable-app)

## Многоуровневый SAST-пайплайн (урок 15)

```
Pre-commit  → Semgrep (быстрые кастомные правила, ~8 сек)
CI/CD       → SonarQube (полный анализ, ~45 сек) + OWASP Dep-Check
Weekly      → Semgrep OWASP ruleset (глубокий аудит)
```
