# ==============================================================================
# Практикум ОП.01: Управление правами доступа NTFS БЕЗ прав Администратора
# Автор: Бражников Иван Алексеевич
# Сценарий для компьютеров учебного класса с ограниченными правами
# ==============================================================================

Write-Host "=== [1/4] Аудит текущего пользователя и его привилегий ===" -ForegroundColor Cyan
Write-Host "Текущий пользователь: $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Yellow
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "Ваш SID: $($identity.User.Value)" -ForegroundColor Green

Write-Host "`nЧленство в локальных группах безопасности:" -ForegroundColor Yellow
$identity.Groups | ForEach-Object {
    try {
        $name = $_.Translate([Security.Principal.NTAccount]).Value
        Write-Host "  - $name ($($_.Value))" -ForegroundColor Gray
    } catch {
        Write-Host "  - $($_.Value)" -ForegroundColor Gray
    }
}

Write-Host "`n=== [2/4] Развертывание лабораторной папки в пользовательском профиле ===" -ForegroundColor Cyan
$LabDir = Join-Path $env:TEMP "WebAppProject_NoAdmin"
if (-not (Test-Path $LabDir)) {
    New-Item -ItemType Directory -Path $LabDir -Force | Out-Null
}
Write-Host "[+] Лабораторный каталог создан: $LabDir" -ForegroundColor Green

$IndexFile = Join-Path $LabDir "index.html"
$SecretFile = Join-Path $LabDir "db_secrets.json"

Set-Content -Path $IndexFile -Value "<h1>Lab Portal</h1>" -Force
Set-Content -Path $SecretFile -Value '{"apiKey": "no_admin_secret_token_2026"}' -Force
Write-Host "[+] Созданы тестовые файлы: index.html, db_secrets.json" -ForegroundColor Green

Write-Host "`n=== [3/4] Настройка избирательных прав доступа NTFS (icacls) ===" -ForegroundColor Cyan
# 1. Отключение наследования прав
icacls $LabDir /inheritance:d | Out-Null
Write-Host "[+] Наследование от родительского каталога отключено." -ForegroundColor Green

# 2. Выдача себе полного доступа
icacls $LabDir /grant "${env:USERNAME}:(OI)(CI)F" | Out-Null

# 3. Выдача группе "Все" (Everyone) прав только на чтение
icacls $LabDir /grant "*S-1-1-0:(OI)(CI)RX" | Out-Null
Write-Host "[+] Настроен доступ: Владельцу ($env:USERNAME) - Full, Всем (Everyone) - Read & Execute." -ForegroundColor Green

# 4. Защита конфиденциального файла
icacls $SecretFile /inheritance:r | Out-Null
icacls $SecretFile /grant "${env:USERNAME}:F" | Out-Null
Write-Host "[+] Секретный файл $SecretFile изолирован (доступ только $env:USERNAME)." -ForegroundColor Green

Write-Host "`n=== [4/4] Верификация настроек DACL ===" -ForegroundColor Cyan
Write-Host "--- Права на каталог $LabDir ---" -ForegroundColor Yellow
icacls $LabDir

Write-Host "`n--- Права на секретный файл $SecretFile ---" -ForegroundColor Yellow
icacls $SecretFile

Write-Host "`n=== [УСПЕХ] Лабораторная работа выполнена без прав Администратора! ===" -ForegroundColor Green
Write-Host "Сделайте скриншот этого окна консоли для отчета преподавателю." -ForegroundColor Cyan
