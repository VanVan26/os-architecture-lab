#!/usr/bin/env bash
# ==============================================================================
# Практикум ОП.01: Управление правами доступа POSIX БЕЗ прав root / sudo
# Автор: Бражников Иван Алексеевич
# Сценарий для Linux-компьютеров с ограниченными правами
# ==============================================================================

set -e

echo "=== [1/4] Аудит текущего пользователя ==="
echo "Текущий пользователь: $(whoami)"
id

echo ""
echo "=== [2/4] Развертывание лабораторной структуры в домашней папке ==="
LAB_DIR="$HOME/webapp_lab_nosudo"
mkdir -p "$LAB_DIR/public" "$LAB_DIR/internal"

INDEX_FILE="$LAB_DIR/public/index.html"
SECRET_FILE="$LAB_DIR/internal/db_secrets.env"

echo "<h1>Linux Unprivileged WebApp</h1>" > "$INDEX_FILE"
echo "SECRET_TOKEN=LinuxNoSudoSecretKey2026" > "$SECRET_FILE"
echo "[+] Лабораторный каталог создан: $LAB_DIR"

echo ""
echo "=== [3/4] Настройка прав доступа (chmod & umask & ACL) ==="
# Открываем публичную папку для всех локальных пользователей
chmod 755 "$LAB_DIR/public"
chmod 644 "$INDEX_FILE"

# Изолируем внутреннюю папку и конфиг
chmod 700 "$LAB_DIR/internal"
chmod 600 "$SECRET_FILE"
echo "[+] Секретный файл $SECRET_FILE закрыт для всех, кроме $(whoami) (600: -rw-------)."

# Проверка и работа с POSIX ACL (работает без sudo для файлов владельца)
if command -v setfacl &>/dev/null; then
    setfacl -m u:nobody:r "$INDEX_FILE" 2>/dev/null || true
    echo "[+] Применен тестовый POSIX ACL."
fi

echo ""
echo "=== [4/4] Верификация параметров безопасности ==="
echo "--- Права на публичные файлы ---"
ls -la "$LAB_DIR/public"

echo ""
echo "--- Права на защищенные файлы ---"
ls -la "$LAB_DIR/internal"

if command -v getfacl &>/dev/null; then
    echo ""
    echo "--- Проверка POSIX ACL на index.html ---"
    getfacl "$INDEX_FILE"
fi

echo ""
echo "=== [УСПЕХ] Лабораторная работа выполнена без прав root/sudo! ==="
echo "Сделайте скриншот этого терминала для отчета преподавателю."
