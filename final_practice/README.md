# sonar-report — скелет утилиты для финальной практики

Скелет CLI-утилиты для финальной практики курса «Безопасный код с SonarQube»
(OTUS). Полная спецификация задания —
[Финальная практика.md](../../Финальная%20практика.md) в корне папки
`lessons/15-lesson/`.

## Запуск

```bash
# Установка зависимостей
python3 -m venv venv
source venv/bin/activate
pip install requests

# Обязательные переменные окружения
export SONAR_URL="http://192.168.30.106:9000"   # или http://localhost:9000
export SONAR_TOKEN="squ_..."                    # ваш Project Analysis Token
export SONAR_PROJECT="vulnerable-app"

# Помощь по командам
python sonar_report.py --help
python sonar_report.py gate --help
python sonar_report.py issues --help
```

## Что в скелете уже есть

- Парсинг CLI-аргументов через `argparse` с 5 подкомандами.
- Класс `SonarConfig` — загрузка конфигурации из env, падает с понятной
  ошибкой если что-то не задано.
- Класс `SonarClient` — HTTP-клиент с basic auth через
  `(SONAR_TOKEN, "")` (правило стенда курса — никогда `admin:<pwd>`).
- Обработка ошибок сети, 401, 403, 404 — с подсказками что именно
  проверить.
- Маппинг CLI-действий triage в названия SonarQube transitions.

## Что нужно реализовать

Все 5 подкоманд сейчас поднимают `NotImplementedError` — это задача:
открыть соответствующий `cmd_*` и написать логику вызова API.
Подсказки и TODO расставлены в docstrings.

Минимальный набор (70% зачёта):

1. `cmd_gate` — `/api/qualitygates/project_status` + exit code.
2. `cmd_issues` — `/api/issues/search` с фильтрами.
3. `cmd_hotspots` — `/api/hotspots/search` с фильтрами.
4. `cmd_summary` — сводный отчёт (метрики + OWASP + severity + CWE + QG).
5. `cmd_triage` — `/api/issues/do_transition` + валидация Issue ≠ Hotspot.

Бонусы — см. спецификацию.

## Полезные API-endpoints (подсказки)

| Endpoint                              | Что использовать для            |
| ------------------------------------- | ------------------------------- |
| `/api/qualitygates/project_status`    | `gate` — статус QG              |
| `/api/issues/search`                  | `issues`, `triage` (валидация)  |
| `/api/hotspots/search`                | `hotspots`, `hotspot-review`    |
| `/api/measures/component`             | `summary` — метрики             |
| `/api/issues/do_transition`           | `triage accept / falsepos`      |
| `/api/issues/add_comment`             | `triage` — комментарий          |
| `/api/hotspots/change_status`         | бонус 3 — ревью Hotspots        |
| `/api/ce/component`                   | бонус 4 — ожидание анализа в CI |

## Частые ошибки

1. **Пустой `securityStandards` в ответе** — не пытайтесь из него
   парсить OWASP. Используйте параметр запроса `owaspTop10-2021=aN`
   напрямую (см. методичку L3 / L9).

2. **HTTP 404 на `/api/project_pull_requests/list`** — это фича
   Developer Edition, в CE недоступна. Не включать в скрипт.

3. **Попытка triage Hotspot через `/api/issues/do_transition`** — 404.
   Hotspots — отдельный endpoint `/api/hotspots/change_status` с другим
   набором статусов (Safe / Acknowledged / Fixed / At Risk).

4. **Забыли `projectKey=` в `/api/hotspots/search`** — endpoint
   принимает именно `projectKey`, не `projects` как в `/api/issues/search`.
   Это одна из типовых ошибок при первом использовании API.

5. **Ожидание SQLi в выводе** — SonarQube CE не детектирует taint-based
   уязвимости на реальном коде. Если `issues --owasp a03` возвращает 0 —
   это не баг, это граница CE. Сравните с `hotspots --owasp a03` —
   Hotspots там могут быть (S2077 и подобные).

## Оформление работы

Перед сдачей проверьте:

- `README.md` вашего решения описывает, какие команды реализованы,
  какие бонусы сделаны, примеры запуска с выводом.
- Нет hardcoded токенов, `admin:<pwd>`, абсолютных локальных путей.
- Код запускается из чистого окружения (следуя вашему же README).
- Скриншоты / текстовые логи работы каждой команды на `vulnerable-app`
  приложены.

Удачи.
