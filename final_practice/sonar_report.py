#!/usr/bin/env python3
"""
sonar_report.py — CLI-утилита для отчётов по проекту через API SonarQube.

Это СКЕЛЕТ для финальной практики курса «Безопасный код с SonarQube» (OTUS).
Содержит базовую структуру — CLI через argparse, HTTP-клиент с basic auth
через `SONAR_TOKEN:` (без пароля), заглушки на 5 обязательных подкоманд.

Задача — доработать этот скелет до рабочей утилиты. Допустимо переписать
целиком, если удобнее — скелет даёт ориентиры, не rigid-контракт.

Полная спецификация и критерии оценки: lessons/15-lesson/Финальная практика.md
"""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from typing import Any

import requests


# ─── Конфигурация через окружение (durable-правило стенда курса) ─────────────
# Никаких hardcoded токенов и `admin:<pwd>` в коде. Токен читается только
# из переменной окружения. Для запуска:
#   export SONAR_URL="http://192.168.30.106:9000"
#   export SONAR_TOKEN="squ_..."
#   export SONAR_PROJECT="vulnerable-app"


@dataclass
class SonarConfig:
    url: str
    token: str
    project: str

    @classmethod
    def from_env(cls) -> "SonarConfig":
        try:
            return cls(
                url=os.environ["SONAR_URL"].rstrip("/"),
                token=os.environ["SONAR_TOKEN"],
                project=os.environ["SONAR_PROJECT"],
            )
        except KeyError as exc:
            raise SystemExit(
                f"Missing required env variable: {exc.args[0]}. "
                f"Set SONAR_URL, SONAR_TOKEN, SONAR_PROJECT before running."
            ) from exc


# ─── HTTP-клиент ─────────────────────────────────────────────────────────────
class SonarClient:
    """Тонкая обёртка над requests с auth через токен в username и пустым паролем.

    Это и есть правильная схема для SonarQube:
        Authorization: Basic base64(f"{token}:")
    Никогда не использовать admin:<pwd> — это durable-правило курса.
    """

    def __init__(self, config: SonarConfig, timeout: float = 10.0):
        self._cfg = config
        self._session = requests.Session()
        self._session.auth = (config.token, "")   # token → username, "" → password
        self._timeout = timeout

    def get(self, path: str, **params: Any) -> dict:
        """GET-запрос к API SonarQube. path — относительный, например /api/issues/search."""
        url = f"{self._cfg.url}{path}"
        # Убираем None-параметры, чтобы не засорять query string
        clean_params = {k: v for k, v in params.items() if v is not None}
        try:
            response = self._session.get(url, params=clean_params, timeout=self._timeout)
        except requests.ConnectionError as exc:
            raise SystemExit(f"Не удалось подключиться к {self._cfg.url}: {exc}") from exc
        except requests.Timeout:
            raise SystemExit(f"Timeout при обращении к {url}") from None

        if response.status_code == 401:
            raise SystemExit(
                "HTTP 401 Unauthorized — токен невалиден или истёк. "
                "Проверьте SONAR_TOKEN (Web UI → My Account → Security → Tokens)."
            )
        if response.status_code == 403:
            raise SystemExit(
                "HTTP 403 Forbidden — у токена нет прав на этот ресурс / проект. "
                "Возможно, нужен Global Analysis Token или права 'Execute Analysis'."
            )
        if response.status_code == 404:
            raise SystemExit(
                f"HTTP 404 Not Found: {url}\n"
                "Проверьте, что projectKey правильный и endpoint поддерживается в CE. "
                "Напоминание: /api/project_pull_requests/list в CE возвращает 404 — "
                "это фича Developer Edition+."
            )
        response.raise_for_status()
        return response.json()

    def post(self, path: str, **data: Any) -> dict:
        """POST-запрос — для transitions и изменений статусов."""
        url = f"{self._cfg.url}{path}"
        clean_data = {k: v for k, v in data.items() if v is not None}
        try:
            response = self._session.post(url, data=clean_data, timeout=self._timeout)
        except requests.ConnectionError as exc:
            raise SystemExit(f"Не удалось подключиться к {self._cfg.url}: {exc}") from exc

        if response.status_code == 401:
            raise SystemExit("HTTP 401 — токен невалиден или истёк.")
        if response.status_code == 403:
            raise SystemExit("HTTP 403 — у токена нет прав на изменение этого Issue.")
        response.raise_for_status()
        # SonarQube иногда возвращает пустое тело на успешный POST
        if not response.content:
            return {}
        return response.json()


# ─── Команда 1: gate ─────────────────────────────────────────────────────────
def cmd_gate(client: SonarClient, project: str, args) -> int:
    """Показать статус Quality Gate. Exit code: 0 если OK, 1 если ERROR/WARN.

    TODO участнику:
      - Реализовать вызов /api/qualitygates/project_status?projectKey=...
      - Распечатать статус и список failed conditions (если ERROR)
      - Возвращать правильный exit code для CI
    """
    data = client.get("/api/qualitygates/project_status", projectKey=project)
    # Ответ: {"projectStatus": {"status": "OK"|"ERROR", "conditions": [...]}}
    raise NotImplementedError(
        "Задача 1: реализуйте вывод Quality Gate + корректный exit code"
    )


# ─── Команда 2: issues ───────────────────────────────────────────────────────
def cmd_issues(client: SonarClient, project: str, args) -> int:
    """Поиск Security Issues с фильтрами OWASP / CWE / severity / type.

    TODO участнику:
      - /api/issues/search с параметрами projects, owaspTop10-2021, cwe,
        severities, types, ps
      - Реализовать форматированный вывод (таблица в --format=text,
        JSON в --format=json)
      - Поддержать --limit (по умолчанию 50) и пагинацию если надо
    """
    raise NotImplementedError("Задача 2: реализуйте /api/issues/search с фильтрами")


# ─── Команда 3: hotspots ─────────────────────────────────────────────────────
def cmd_hotspots(client: SonarClient, project: str, args) -> int:
    """Поиск Security Hotspots с фильтрами.

    TODO участнику:
      - /api/hotspots/search с параметрами projectKey, owaspTop10-2021,
        cwe, status, resolution
      - НАПОМНИТЬ В --help: Hotspots — отдельная сущность от Issues,
        статусы Accepted / False Positive неприменимы.
    """
    raise NotImplementedError("Задача 3: реализуйте /api/hotspots/search")


# ─── Команда 4: summary ──────────────────────────────────────────────────────
def cmd_summary(client: SonarClient, project: str, args) -> int:
    """Сводный отчёт по проекту: метрики + OWASP + severity + топ CWE + QG.

    TODO участнику:
      - /api/measures/component с набором metricKeys
      - Обход OWASP A01..A10 (как bash-цикл в methodичке L9 раздел 9.1)
      - Группировка Issues по severity
      - Топ CWE по количеству (из тэгов Issues)
      - Quality Gate статус в конце
      - Два режима вывода: text (человеку) и json (в pipe)
    """
    raise NotImplementedError(
        "Задача 4: реализуйте summary — метрики + OWASP + severity + CWE + QG"
    )


# ─── Команда 5: triage ───────────────────────────────────────────────────────
TRANSITIONS = {
    "accept":   "accept",          # Issue → Accepted
    "falsepos": "falsepositive",   # Issue → False Positive
    "reopen":   "reopen",          # Accepted/FP → Open
}


def cmd_triage(client: SonarClient, project: str, args) -> int:
    """Перевод Issue в статус через /api/issues/do_transition.

    TODO участнику:
      - Валидировать --issue-key: через /api/issues/search?issues=<key>
        убедиться, что это Issue (а не Hotspot). Hotspot в этом ответе
        не появится — это и будет сигналом.
      - Проверить, что для accept / falsepos передан --comment.
      - Вызвать /api/issues/do_transition (+ /api/issues/add_comment если
        комментарий обязателен).
      - Вернуть понятный exit code и сообщение пользователю.
    """
    transition = TRANSITIONS.get(args.action)
    if not transition:
        raise SystemExit(f"Unknown transition: {args.action}")
    if args.action in ("accept", "falsepos") and not args.comment:
        raise SystemExit(f"--comment обязателен для действия '{args.action}'")
    raise NotImplementedError(
        "Задача 5: реализуйте triage + валидацию Issue vs Hotspot"
    )


# ─── CLI-парсер ──────────────────────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="sonar-report",
        description=(
            "CLI-утилита для отчётов по проекту через SonarQube REST API. "
            "Конфигурация через env: SONAR_URL, SONAR_TOKEN, SONAR_PROJECT."
        ),
    )
    p.add_argument("--format", choices=["text", "json"], default="text",
                   help="Формат вывода (по умолчанию text).")
    sub = p.add_subparsers(dest="command", required=True)

    # gate
    sub.add_parser("gate", help="Статус Quality Gate (exit code 0 / 1).")

    # issues
    p_iss = sub.add_parser("issues", help="Поиск Security Issues с фильтрами.")
    p_iss.add_argument("--owasp",    help="OWASP Top 10 2021 категория: a01..a10.")
    p_iss.add_argument("--cwe",      help="CWE ID (например, 798).")
    p_iss.add_argument("--severity", help="BLOCKER / CRITICAL / MAJOR / MINOR / INFO.")
    p_iss.add_argument("--type",     choices=["VULNERABILITY", "BUG", "CODE_SMELL"],
                       help="Тип (legacy-ключи SQ API: VULNERABILITY=Security Issue, BUG=Reliability Issue).")
    p_iss.add_argument("--limit",    type=int, default=50, help="Лимит записей (default 50).")

    # hotspots
    p_ht = sub.add_parser("hotspots", help="Поиск Security Hotspots с фильтрами.")
    p_ht.add_argument("--status",     choices=["TO_REVIEW", "REVIEWED"], help="Статус Hotspot.")
    p_ht.add_argument("--resolution", choices=["SAFE", "ACKNOWLEDGED", "FIXED", "AT_RISK"],
                      help="Разрешение (только если status=REVIEWED).")
    p_ht.add_argument("--owasp",      help="OWASP Top 10 2021 категория.")
    p_ht.add_argument("--cwe",        help="CWE ID.")

    # summary
    sub.add_parser("summary", help="Сводный отчёт: метрики + OWASP + severity + CWE + QG.")

    # triage
    p_tr = sub.add_parser("triage", help="Перевод Issue в статус Accepted / False Positive.")
    p_tr.add_argument("action", choices=["accept", "falsepos", "reopen"])
    p_tr.add_argument("--issue-key", required=True, help="Ключ Issue (не Hotspot).")
    p_tr.add_argument("--comment",   help="Комментарий (обязателен для accept / falsepos).")

    return p


# ─── Диспетчер ───────────────────────────────────────────────────────────────
COMMANDS = {
    "gate":     cmd_gate,
    "issues":   cmd_issues,
    "hotspots": cmd_hotspots,
    "summary":  cmd_summary,
    "triage":   cmd_triage,
}


def main() -> int:
    args = build_parser().parse_args()
    config = SonarConfig.from_env()
    client = SonarClient(config)
    handler = COMMANDS[args.command]
    return handler(client, config.project, args) or 0


if __name__ == "__main__":
    sys.exit(main())
