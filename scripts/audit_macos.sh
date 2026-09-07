#!/bin/zsh
# Скрипт автоматизированного сбора аппаратных параметров (macOS)
# ОП.01 Операционные системы и архитектура АС

echo "\033[1;36m==================================================\033[0m"
echo "\033[1;36m  АРХИТЕКТУРНЫЙ АУДИТ РАБОЧЕЙ СТАНЦИИ (macOS)     \033[0m"
echo "\033[1;36m==================================================\033[0m"

echo "\n\033[1;33m--- 1. ПЛАТФОРМА И ПРОЦЕССОР (CPU) ---\033[0m"
system_profiler SPHardwareDataType | grep -E "Model Name|Model Identifier|Chip|Processor Name|Total Number of Cores|Memory"

echo "\n\033[1;33m--- 2. ИЕРАРХИЯ ПАМЯТИ И КЭША ---\033[0m"
sysctl -a 2>/dev/null | grep -E "hw.l1|hw.l2|hw.l3|hw.memsize"

echo "\n\033[1;33m--- 3. ДИСКОВАЯ ПОДСИСТЕМА (STORAGE) ---\033[0m"
diskutil list | grep -E "GUID_partition_scheme|Apple_APFS"
system_profiler SPStorageDataType | grep -E "Device Name|Protocol|Solid State|Capacity"

echo "\n\033[1;33m--- 4. ГРАФИЧЕСКИЙ АДАПТЕР (GPU) ---\033[0m"
system_profiler SPDisplaysDataType | grep -E "Chipset Model|Type|Total Number of Cores|Resolution"

echo "\n\033[1;32m[+] Аудит завершен. Перенесите данные в отчет практической работы.\033[0m"
