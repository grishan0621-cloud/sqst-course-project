# Configuration Audit — Урок 14

Дата аудита: 2026-01 | Версия проекта: `1.0-lesson14`

---

## Антипаттерны — найдены и исправлены

### ❌ → ✅ Антипаттерн 1: Слепое NOSONAR

**Было:**
```python
result = eval(user_input)  # NOSONAR
```
**Стало:**
```python
result = eval(user_input)  # NOSONAR: учебный пример eval (CWE-95), намеренная уязвимость
```
**Статус:** ✅ Исправлено

### ❌ → ✅ Антипаттерн 2: Избыточные исключения из анализа

**Было:**
```ini
sonar.exclusions=**/*,tests/**,docs/**,scripts/**
```
**Стало:**
```ini
sonar.exclusions=**/__pycache__/**,**/*.pyc,**/node_modules/**
```
**Статус:** ✅ Исправлено — убраны исключения production-кода

### ❌ → ✅ Антипаттерн 3: Несогласованные Quality Gate

**Было:** Для `main` — строгий QG, для feature-веток — без QG

**Стало:** Единый QG `OTUS-Strict` для всех веток

**Статус:** ✅ Исправлено в `.gitlab-ci.yml`

---

## Best Practices — задокументированы

1. **NOSONAR всегда с обоснованием** — см. `fp-analysis.md`
2. **Quality Gate не отключается в пайплайне** — `allow_failure: false`
3. **Токены имеют срок действия** — см. `access-policy.md`
4. **Исключения минимальны** — только артефакты сборки
5. **Hotspot-ы проходят ручной ревью** — см. `hotspot-review.md`
6. **FP документируются** — в `fp-analysis.md`
7. **sonar-project.properties в репозитории** — конфиг версионирован
