# ==============================================================================
# Практикум: Управление пользователями, группами и правами доступа в Windows
# Автор: Бражников Иван Алексеевич
# Дисциплина: ОП.01 «Операционные системы, среды и архитектура аппаратных средств»
# ==============================================================================

#Requires -RunAsAdministrator

Write-Host "=== [1/5] Проверка прав Администратора ===" -ForegroundColor Cyan
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "[-] Данный скрипт должен быть запущен в сессии PowerShell от имени Администратора!"
    exit 1
}
Write-Host "[+] Сессия с повышенными привилегиями подтверждена.`n" -ForegroundColor Green

Write-Host "=== [2/5] Создание локальных групп ===" -ForegroundColor Cyan
$groups = @("DevsGroup", "QAGroup")
foreach ($g in $groups) {
    if (-not (Get-LocalGroup -Name $g -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $g -Description "Группа лаборатории безопасности: $g" | Out-Null
        Write-Host "[+] Создана локальная группа: $g" -ForegroundColor Green
    } else {
        Write-Host "[!] Группа $g уже существует." -ForegroundColor Yellow
    }
}

Write-Host "`n=== [3/5] Создание пользователей и привязка к группам ===" -ForegroundColor Cyan
$users = @(
    @{ Name = "IvanDev"; FullName = "Ivan Developer"; Group = "DevsGroup" },
    @{ Name = "OlgaQA";  FullName = "Olga QA Engineer"; Group = "QAGroup" }
)

$SecurePass = ConvertTo-SecureString "P@ssw0rd2026!" -AsPlainText -Force

foreach ($u in $users) {
    if (-not (Get-LocalUser -Name $u.Name -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $u.Name -FullName $u.FullName -Password $SecurePass -PasswordNeverExpires $true -Description "Студенческий стенд ОП.01" | Out-Null
        Add-LocalGroupMember -Group $u.Group -Member $u.Name | Out-Null
        Write-Host "[+] Пользователь $($u.Name) создан и добавлен в группу $($u.Group)" -ForegroundColor Green
    } else {
        Write-Host "[!] Пользователь $($u.Name) уже существует." -ForegroundColor Yellow
    }
}

Write-Host "`n=== [4/5] Развертывание каталога проекта и настройка NTFS DACL ===" -ForegroundColor Cyan
$ProjectDir = "C:\WebAppProject"
if (-not (Test-Path $ProjectDir)) {
    New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
    Write-Host "[+] Создан каталог: $ProjectDir" -ForegroundColor Green
}

# Отключение наследования прав и удаление унаследованных правил
icacls $ProjectDir /inheritance:r | Out-Null

# Выдача прав: SYSTEM и Администраторы - полный доступ, DevsGroup - изменение, QAGroup - чтение
icacls $ProjectDir /grant "SYSTEM:(OI)(CI)F" | Out-Null
icacls $ProjectDir /grant "Администраторы:(OI)(CI)F" | Out-Null
icacls $ProjectDir /grant "DevsGroup:(OI)(CI)M" | Out-Null
icacls $ProjectDir /grant "QAGroup:(OI)(CI)RX" | Out-Null
Write-Host "[+] На каталог $ProjectDir настроены избирательные права NTFS." -ForegroundColor Green

# Создание конфиденциального файла с ограничением доступа
$SecretFile = Join-Path $ProjectDir "db_secrets.json"
@"
{
  "Database": {
    "Host": "127.0.0.1",
    "Password": "SecretWindowsServerPass2026!"
  }
}
"@ | Out-File -FilePath $SecretFile -Encoding UTF8

icacls $SecretFile /inheritance:r | Out-Null
icacls $SecretFile /grant "SYSTEM:F" | Out-Null
icacls $SecretFile /grant "Администраторы:F" | Out-Null
Write-Host "[+] Создан секретный файл $SecretFile (доступ только Администраторам)." -ForegroundColor Green

Write-Host "`n=== [5/5] Верификация параметров безопасности ===" -ForegroundColor Cyan
Write-Host "--- Список созданных пользователей ---" -ForegroundColor Yellow
Get-LocalUser -Name "IvanDev", "OlgaQA" | Select-Object Name, FullName, Enabled, SID | Format-Table -AutoSize

Write-Host "--- Состав группы DevsGroup ---" -ForegroundColor Yellow
Get-LocalGroupMember -Group "DevsGroup" | Format-Table -AutoSize

Write-Host "--- Состав группы QAGroup ---" -ForegroundColor Yellow
Get-LocalGroupMember -Group "QAGroup" | Format-Table -AutoSize

Write-Host "--- Права доступа NTFS на C:\WebAppProject ---" -ForegroundColor Yellow
icacls $ProjectDir

Write-Host "--- Права доступа NTFS на секретный файл ---" -ForegroundColor Yellow
icacls $SecretFile

Write-Host "`n=== [УСПЕХ] Лабораторная среда Windows успешно сконфигурирована! ===" -ForegroundColor Green
