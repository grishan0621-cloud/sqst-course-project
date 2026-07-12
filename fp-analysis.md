# FP/FN Analysis — Решения по замечаниям SonarQube

Проект: `vulnerable-app`

Журнал решений по триажу замечаний SonarQube. Каждая запись —
одно осознанное решение команды (FP / Won't Fix / Confirmed) с
обоснованием, автором и датой. Заполняется руками вместе с
триажем в Sonar UI.

---

## 1. Hard-coded credentials DB_PASSWORD — Won't Fix

| Поле          | Значение                                                |
|---------------|---------------------------------------------------------|
| Правило       | python:S2068 (Vulnerability, MAJOR)                     |
| Файл          | backend/app.py:31 (`DB_PASSWORD = "admin123"`)   |
| Решение       | Won't Fix                                               |
| Обоснование   | Тестовые данные, намеренно в коде для демонстрации CWE-798 (Hard-coded Credentials). В production не попадает. |
| Дата          | 2026-04-22                                              |
| Ответственный | Ф. Игнатенко                                            |
