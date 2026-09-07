# Скрипт автоматизированного сбора аппаратных параметров (Windows)
# ОП.01 Операционные системы и архитектура АС

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " АРХИТЕКТУРНЫЙ АУДИТ РАБОЧЕЙ СТАНЦИИ (WINDOWS)   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Процессор
Write-Host "`n--- 1. ЦЕНТРАЛЬНЫЙ ПРОЦЕССОР (CPU) ---" -ForegroundColor Yellow
$cpu = Get-CimInstance Win32_Processor
[PSCustomObject]@{
    "Модель" = $cpu.Name
    "Физических ядер" = $cpu.NumberOfCores
    "Логических потоков" = $cpu.NumberOfLogicalProcessors
    "Базовая частота (МГц)" = $cpu.MaxClockSpeed
    "Кэш L2 (КБ)" = $cpu.L2CacheSize
    "Кэш L3 (КБ)" = $cpu.L3CacheSize
    "Виртуализация в BIOS" = if ($cpu.VirtualizationFirmwareEnabled) { "Включена" } else { "Отключена" }
} | Format-List

# 2. Память
Write-Host "`n--- 2. ОПЕРАТИВНАЯ ПАМЯТЬ (RAM) ---" -ForegroundColor Yellow
Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, DeviceLocator, Manufacturer, PartNumber, @{Name="Объем (ГБ)";Expression={$_.Capacity/1GB}}, @{Name="Частота (МГц)";Expression={$_.Speed}} | Format-Table -AutoSize

# 3. Накопители
Write-Host "`n--- 3. ДИСКОВАЯ ПОДСИСТЕМА (STORAGE) ---" -ForegroundColor Yellow
Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, BusType, @{Name="Объем (ГБ)";Expression={[math]::Round($_.Size/1GB, 2)}}, HealthStatus | Format-Table -AutoSize

# 4. Материнская плата и BIOS
Write-Host "`n--- 4. МАТЕРИНСКАЯ ПЛАТА И ПРОШИВКА BIOS ---" -ForegroundColor Yellow
$board = Get-CimInstance Win32_BaseBoard
$bios = Get-CimInstance Win32_BIOS
[PSCustomObject]@{
    "Производитель платы" = $board.Manufacturer
    "Модель платы" = $board.Product
    "Версия BIOS" = $bios.SMBIOSBIOSVersion
    "Дата прошивки" = $bios.ReleaseDate
} | Format-List

Write-Host "`n[+] Аудит завершен. Перенесите данные в отчет практической работы." -ForegroundColor Green
