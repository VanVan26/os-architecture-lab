#!/usr/bin/env bash
# ==============================================================================
# Практикум: Управление пользователями, группами и правами доступа в macOS
# Автор: Бражников Иван Алексеевич
# Дисциплина: ОП.01 «Операционные системы, среды и архитектура аппаратных средств»
# ==============================================================================

set -e

echo "=== [1/5] Проверка прав суперпользователя в macOS ==="
if [ "$EUID" -ne 0 ]; then
  echo "[-] Ошибка: Для управления Directory Service скрипт должен быть запущен через sudo."
  exit 1
fi
echo "[+] Права root подтверждены."

echo ""
echo "=== [2/5] Создание локальных групп через dscl ==="
create_group_if_missing() {
    local grp_name="$1"
    local gid="$2"
    if dscl . -read "/Groups/$grp_name" &>/dev/null; then
        echo "[!] Группа $grp_name уже существует."
    else
        dscl . -create "/Groups/$grp_name"
        dscl . -create "/Groups/$grp_name" PrimaryGroupID "$gid"
        echo "[+] Группа $grp_name создана с GID $gid."
    fi
}

create_group_if_missing "devsteam" "1060"
create_group_if_missing "qateam" "1061"

echo ""
echo "=== [3/5] Создание пользователей через sysadminctl ==="
if id "devuser" &>/dev/null; then
    echo "[!] Пользователь devuser уже существует."
else
    sysadminctl -addUser devuser -fullName "Dev User" -password "P@ssword2026!" -home /Users/devuser
    dscl . -append /Groups/devsteam GroupMembership devuser
    echo "[+] Пользователь devuser создан и добавлен в devsteam."
fi

if id "qauser" &>/dev/null; then
    echo "[!] Пользователь qauser уже существует."
else
    sysadminctl -addUser qauser -fullName "QA User" -password "P@ssword2026!" -home /Users/qauser
    dscl . -append /Groups/qateam GroupMembership qauser
    echo "[+] Пользователь qauser создан и добавлен в qateam."
fi

echo ""
echo "=== [4/5] Настройка каталога проекта и прав доступа ==="
PROJECT_DIR="/Users/Shared/WebAppProject"
mkdir -p "$PROJECT_DIR"
chown -R devuser:devsteam "$PROJECT_DIR"
chmod 770 "$PROJECT_DIR"

# Выдача расширенных прав ACL пользователю qauser на чтение
chmod +a "qauser allow read,execute" "$PROJECT_DIR"
echo "[+] На каталог $PROJECT_DIR выставлены POSIX 770 и добавлен macOS ACL для qauser."

# Создание секретного файла
SECRET_FILE="$PROJECT_DIR/secrets.json"
echo '{"api_key": "macos_secret_key_2026"}' > "$SECRET_FILE"
chown root:wheel "$SECRET_FILE"
chmod 600 "$SECRET_FILE"
echo "[+] Секретный файл $SECRET_FILE защищен (600, root:wheel)."

echo ""
echo "=== [5/5] Верификация настроек в macOS ==="
echo "--- Пользователи и их группы ---"
id devuser
id qauser

echo ""
echo "--- Права доступа на каталог проекта с флагом -e (ACL) ---"
ls -lde "$PROJECT_DIR"

echo ""
echo "--- Права на секретный файл ---"
ls -la "$SECRET_FILE"

echo ""
echo "=== [УСПЕХ] Лабораторная среда macOS успешно развернута! ==="
