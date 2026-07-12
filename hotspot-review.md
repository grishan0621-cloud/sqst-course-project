# Security Hotspot Review — Урок 7

Проект: `vulnerable-app` | Версия: `1.0`

---

## Что такое Security Hotspot

Security Hotspot — это место в коде, которое *может* быть уязвимым, но требует ручной проверки. В отличие от Vulnerability, SonarQube не уверен в наличии реального риска.

Статусы Hotspot:
- `TO_REVIEW` — требует проверки (начальный статус)
- `ACKNOWLEDGED` — проверен, риск осознан
- `FIXED` — исправлен
- `SAFE` — проверен, безопасен в данном контексте

---

## Реестр Hotspot-ов проекта

### HS-001: MD5 в hash_password()

| Поле | Значение |
|------|----------|
| Правило | `python:S4790` — Weak Hashing |
| Файл | `backend/app.py`, строка ~130 |
| OWASP | A02:2021 Cryptographic Failures |
| Статус | **ACKNOWLEDGED** |
| Решение | Намеренная уязвимость для демонстрации MD5. Backlog: заменить на bcrypt. |
| Ответственный | Instructor |

### HS-002: subprocess с shell=True в ping()

| Поле | Значение |
|------|----------|
| Правило | `python:S4721` — OS Command Injection |
| Файл | `backend/app.py`, строка ~97 |
| OWASP | A03:2021 Injection |
| Статус | **ACKNOWLEDGED** |
| Решение | Критическая уязвимость для демонстрации CWE-78. Добавить в backlog исправления. |
| Ответственный | Instructor |

### HS-003: debug=True в app.run()

| Поле | Значение |
|------|----------|
| Правило | `python:S5659` — Debug Mode |
| Файл | `backend/app.py`, последняя строка |
| OWASP | A05:2021 Security Misconfiguration |
| Статус | **ACKNOWLEDGED** |
| Решение | Намеренно для учебного окружения. В production использовать `debug=False`. |
| Ответственный | Instructor |

---

## Выводы

| Категория | Количество |
|-----------|------------|
| Критические (ACKNOWLEDGED) | 2 |
| Некритические (SAFE) | 1 |
| Требуют исправления | 1 (HS-002, добавлен в backlog) |

Все Hotspot-ы проверены вручную. Реальные риски задокументированы в `fp-analysis.md`.
