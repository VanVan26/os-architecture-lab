#!/bin/bash
# Скрипт автоматизированного сбора аппаратных параметров (Linux)
# ОП.01 Операционные системы и архитектура АС

echo -e "\033[1;36m==================================================\033[0m"
echo -e "\033[1;36m  АРХИТЕКТУРНЫЙ АУДИТ РАБОЧЕЙ СТАНЦИИ (LINUX)     \033[0m"
echo -e "\033[1;36m==================================================\033[0m"

echo -e "\n\033[1;33m--- 1. ЦЕНТРАЛЬНЫЙ ПРОЦЕССОР (CPU) ---\033[0m"
lscpu | grep -E "Model name:|Socket\(s\):|Core\(s\) per socket:|Thread\(s\) per core:|CPU max MHz:|L1d cache:|L1i cache:|L2 cache:|L3 cache:|Flags:"

echo -e "\n\033[1;33m--- 2. ОПЕРАТИВНАЯ ПАМЯТЬ (RAM) ---\033[0m"
free -h
if command -v dmidecode &> /dev/null && [ "$EUID" -eq 0 ]; then
    echo -e "\nСлоты и физические модули RAM:"
    dmidecode --type memory | grep -E "Size:|Speed:|Type:|Manufacturer:|Configured Memory Speed:"
else
    echo "Запустите с sudo для получения детальной информации о слотах памяти (dmidecode)."
fi

echo -e "\n\033[1;33m--- 3. ДИСКОВАЯ ПОДСИСТЕМА (STORAGE) ---\033[0m"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT

echo -e "\n\033[1;33m--- 4. МАТЕРИНСКАЯ ПЛАТА И СИСТЕМА ---\033[0m"
[ -d /sys/firmware/efi ] && echo "Режим прошивки: UEFI" || echo "Режим прошивки: Legacy BIOS"
if command -v dmidecode &> /dev/null && [ "$EUID" -eq 0 ]; then
    dmidecode --type baseboard | grep -E "Manufacturer:|Product Name:|Version:"
    dmidecode --type bios | grep -E "Vendor:|Version:|Release Date:"
fi

echo -e "\n\033[1;32m[+] Аудит завершен. Перенесите данные в отчет практической работы.\033[0m"
