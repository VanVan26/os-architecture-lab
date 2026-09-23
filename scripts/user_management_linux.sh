#!/usr/bin/env bash
# ==============================================================================
# Практикум: Управление пользователями, группами и правами доступа в Linux
# Автор: Бражников Иван Алексеевич
# Дисциплина: ОП.01 «Операционные системы, среды и архитектура аппаратных средств»
# ==============================================================================

set -e

echo "=== [1/5] Проверка прав суперпользователя ==="
if [ "$EUID" -ne 0 ]; then
  echo "[-] Ошибка: Данный скрипт должен быть запущен с правами root (sudo)."
  exit 1
fi
echo "[+] Права root подтверждены."

echo ""
echo "=== [2/5] Создание групп разработчиков и тестировщиков ==="
groupadd -f devs
groupadd -f qa
echo "[+] Группы 'devs' (GID: $(getent group devs | cut -d: -f3)) и 'qa' (GID: $(getent group qa | cut -d: -f3)) готовы."

echo ""
echo "=== [3/5] Создание пользователей ==="
# Создание ivan_dev
if id "ivan_dev" &>/dev/null; then
    echo "[!] Пользователь ivan_dev уже существует."
else
    useradd -m -s /bin/bash -c "Ivan Developer" -g devs ivan_dev
    echo "ivan_dev:P@ssword2026!" | chpasswd
    echo "[+] Пользователь ivan_dev создан в группе devs."
fi

# Создание olga_qa
if id "olga_qa" &>/dev/null; then
    echo "[!] Пользователь olga_qa уже существует."
else
    useradd -m -s /bin/bash -c "Olga QA Engineer" -g qa olga_qa
    echo "olga_qa:P@ssword2026!" | chpasswd
    echo "[+] Пользователь olga_qa создан в группе qa."
fi

echo ""
echo "=== [4/5] Развертывание каталога проекта и настройка SGID / прав ==="
PROJECT_DIR="/srv/webapp"
mkdir -p "$PROJECT_DIR"
chown -R ivan_dev:devs "$PROJECT_DIR"

# Права 2770: SGID (2) + rwx владельцу (7) + rwx группе (7) + ничего остальным (0)
chmod 2770 "$PROJECT_DIR"
echo "[+] На каталог $PROJECT_DIR установлены права 2770 (SGID)."

# Настройка POSIX ACL для группы qa (чтение и переход)
if command -v setfacl &>/dev/null; then
    setfacl -m g:qa:rx "$PROJECT_DIR"
    setfacl -d -m g:qa:rx "$PROJECT_DIR"
    echo "[+] Для группы 'qa' установлены ACL (чтение и доступ к каталогу)."
else
    echo "[!] Утилита setfacl не найдена. Установите пакет acl (apt install acl)."
fi

# Создание секретного конфигурационного файла (доступ только root)
SECRET_FILE="$PROJECT_DIR/db_secrets.env"
echo "DB_HOST=127.0.0.1" > "$SECRET_FILE"
echo "DB_PASSWORD=SuperSecretRootPass!" >> "$SECRET_FILE"
chown root:root "$SECRET_FILE"
chmod 600 "$SECRET_FILE"
echo "[+] Секретный файл $SECRET_FILE создан с правами 600 (только root)."

echo ""
echo "=== [5/5] Верификация настроек ==="
echo "--- Информация о пользователях ---"
id ivan_dev
id olga_qa

echo ""
echo "--- Права доступа на каталог проекта ---"
ls -ld "$PROJECT_DIR"

if command -v getfacl &>/dev/null; then
    echo ""
    echo "--- Текущие ACL на каталог проекта ---"
    getfacl "$PROJECT_DIR"
fi

echo ""
echo "--- Права доступа на секретный файл ---"
ls -l "$SECRET_FILE"

echo ""
echo "=== [УСПЕХ] Лабораторная среда Linux успешно развернута! ==="
