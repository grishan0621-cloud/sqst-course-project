"""
backend/app.py — Учебное веб-приложение с намеренными уязвимостями
==========================================================================
Курс OTUS DevSecOps: SonarQube от А до Я
Уязвимое приложение — управление замечаниями, FP/FN, NOSONAR

ВНИМАНИЕ: Этот код содержит НАМЕРЕННЫЕ уязвимости для учебных целей.
НЕ используйте этот код в production-окружении!

Уязвимости для демонстрации и их маппинг на OWASP Top 10:
  - Hard-coded credentials (CWE-798) → OWASP A02:2021 Cryptographic Failures
  - SQL Injection (CWE-89) → OWASP A03:2021 Injection
  - Command Injection (CWE-78) → OWASP A03:2021 Injection
  - Path Traversal (CWE-22) → OWASP A05:2021 Security Misconfiguration (или A01 Access Control)
  - Weak hash (MD5) (CWE-326) → OWASP A02:2021 Cryptographic Failures
"""

import os
import sqlite3
import subprocess
import hashlib
from flask import Flask, request, jsonify

app = Flask(__name__)

# =============================================================================
# УЯЗВИМОСТЬ 1: Hard-coded credentials (CWE-798)
# Связь с OWASP: A02:2021 Cryptographic Failures
# SonarQube: "Credentials should not be hard-coded" — CRITICAL
# =============================================================================
DB_PASSWORD = "admin123"          # УЯЗВИМОСТЬ: пароль в коде (CWE-798, A02)
SECRET_KEY  = "mysecretkey12345"  # УЯЗВИМОСТЬ: секрет в коде (CWE-798, A02)
API_TOKEN   = "tok_prod_abc123xyz" # УЯЗВИМОСТЬ: токен в коде (CWE-798, A02)


def get_db_connection():
    """Создаёт подключение к базе данных."""
    conn = sqlite3.connect("users.db")
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Инициализирует базу данных с тестовыми данными."""
    conn = get_db_connection()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT,
            password TEXT,
            role TEXT
        )
    """)
    conn.execute("INSERT OR IGNORE INTO users VALUES (1,'admin','admin123','admin')")
    conn.execute("INSERT OR IGNORE INTO users VALUES (2,'alice','pass456','user')")
    conn.commit()
    conn.close()


# =============================================================================
# УЯЗВИМОСТЬ 2: SQL Injection (CWE-89)
# Связь с OWASP: A03:2021 Injection
# SonarQube: "SQL queries should not be vulnerable to injection attacks" — CRITICAL
# =============================================================================
@app.route("/login", methods=["POST"])
def login():
    """
    Небезопасная аутентификация — уязвима к SQL Injection.
    CWE-89 (SQL Injection) → OWASP A03:2021 Injection

    Пример атаки: username = "admin' --"
    Запрос становится: SELECT * FROM users WHERE username='admin' --' AND password='...'
    """
    username = request.form.get("username", "")
    password = request.form.get("password", "")

    conn = get_db_connection()
    # УЯЗВИМОСТЬ: строковая конкатенация в SQL-запросе (CWE-89, A03)
    query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
    user = conn.execute(query).fetchone()  # SQL INJECTION!
    conn.close()

    if user:
        return jsonify({"status": "ok", "role": user["role"]})
    return jsonify({"status": "error", "message": "Invalid credentials"}), 401


# =============================================================================
# УЯЗВИМОСТЬ 3: Command Injection (CWE-78)
# Связь с OWASP: A03:2021 Injection
# SonarQube: "OS commands should not be vulnerable to injection attacks" — CRITICAL
# =============================================================================
@app.route("/ping", methods=["GET"])
def ping():
    """
    Небезопасный пинг — уязвим к Command Injection.
    CWE-78 (Command Injection) → OWASP A03:2021 Injection

    Пример атаки: host = "8.8.8.8; cat /etc/passwd"
    """
    host = request.args.get("host", "localhost")
    # УЯЗВИМОСТЬ: пользовательский ввод передаётся напрямую в shell (CWE-78, A03)
    result = subprocess.check_output(f"ping -c 1 {host}", shell=True)  # CMD INJECTION!
    return result.decode()


# =============================================================================
# УЯЗВИМОСТЬ 4: Path Traversal (CWE-22)
# Связь с OWASP: A05:2021 Security Misconfiguration (или A01 Access Control)
# SonarQube: "Path traversal should not be possible" — CRITICAL
# =============================================================================
@app.route("/file", methods=["GET"])
def read_file():
    """
    Небезопасное чтение файлов — уязвимо к Path Traversal.
    CWE-22 (Path Traversal) → OWASP A05:2021 Security Misconfiguration

    Пример атаки: filename = "../../etc/passwd"
    """
    filename = request.args.get("filename", "readme.txt")
    base_dir = "/var/app/files"
    # УЯЗВИМОСТЬ: нет валидации пути (CWE-22, A05)
    filepath = os.path.join(base_dir, filename)  # PATH TRAVERSAL!
    with open(filepath) as f:
        return f.read()


# =============================================================================
# УЯЗВИМОСТЬ 5: Weak Cryptography (CWE-326 / CWE-327)
# Связь с OWASP: A02:2021 Cryptographic Failures
# SonarQube: "Cryptographic hash functions should not be vulnerable" — HIGH
# =============================================================================
def hash_password(password: str) -> str:
    """
    Небезопасное хеширование — использует MD5 без соли.
    CWE-326 (Weak Hash) → OWASP A02:2021 Cryptographic Failures
    MD5 считается криптографически слабым с 1996 года.
    """
    # УЯЗВИМОСТЬ: MD5 слаб, нет соли (CWE-326, A02)
    return hashlib.md5(password.encode()).hexdigest()  # WEAK CRYPTO! NOSONAR: учебный пример (CWE-326, Won't Fix)


# =============================================================================
# ЧИСТЫЙ КОД ДЛЯ СРАВНЕНИЯ: Правильный способ хеширования
# =============================================================================
import secrets

def hash_password_secure(password: str) -> str:
    """
    БЕЗОПАСНЫЙ вариант: bcrypt или argon2 с солью.
    Показываем студентам — вот как надо!
    """
    import hashlib
    salt = secrets.token_hex(16)
    # Используем SHA-256 с солью (в реальном коде — bcrypt/argon2)
    return hashlib.sha256((salt + password).encode()).hexdigest() + ":" + salt


if __name__ == "__main__":
    init_db()
    # УЯЗВИМОСТЬ: debug=True в production раскрывает трассировки ошибок
    app.run(host="0.0.0.0", port=5000, debug=True)
