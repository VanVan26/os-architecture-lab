# Руководство: Выполнение лабораторной работы БЕЗ прав root / sudo / Администратора (План «Б»)

> **Для кого это руководство:**  
> Если вы выполняете работу на компьютерах учебного класса колледжа, где учетные записи заблокированы групповыми политиками, нет пароля от `sudo` или нет прав локального Администратора в Windows.

---

## 🚀 ВАРИАНТ 1 (РЕКОМЕНДУЕМЫЙ): Запуск в бесплатном облачном терминале с root

Вам не нужно ничего устанавливать на ПК колледжа. Вы можете открыть полноценную виртуальную машину Linux прямо в веб-браузере с правами суперпользователя `root` без пароля.

### Способ 1.1. GitHub Codespaces (Самый удобный)
Каждому студенту с аккаунтом GitHub бесплатно доступно 60 часов работы в месяц:
1. Откройте репозиторий практикума: [github.com/VanVan26/os-architecture-lab](https://github.com/VanVan26/os-architecture-lab)
2. Нажмите зеленую кнопку **«<> Code»** $\rightarrow$ перейдите на вкладку **«Codespaces»**.
3. Нажмите **«Create codespace on main»**.
4. Через 20–30 секунд в браузере откроется полнофункциональная среда **VS Code** с терминалом Ubuntu.
5. В терминале введите:
   ```bash
   sudo whoami
   # Вывод: root (без запроса пароля!)
   ```
6. Выполняйте все команды из основной инструкции [USER_MANAGEMENT_LAB.md](USER_MANAGEMENT_LAB.md) без ограничений!

### Способ 1.2. WebVM / Killercoda (Мгновенно без регистрации)
* **[Killercoda Ubuntu Playground](https://killercoda.com/playgrounds/scenario/ubuntu)** — чистая консоль Ubuntu с root за 5 секунд.
* **[WebVM (webvm.io)](https://webvm.io/)** — виртуальная машина Debian x86 прямо на WebAssembly в браузере.

---

## 🐧 ВАРИАНТ 2: Локальный Linux без sudo (Песочница User Namespaces)

В ядре современных дистрибутивов Linux (Ubuntu, Debian, Astra, Fedora) включена поддержка **User Namespaces**. Она позволяет обычному пользователю создать изолированное пространство процессов и стать внутри него виртуальным `root (UID 0)` без ввода пароля!

### 2.1. Вход в виртуальный root-режим:
Выполните в терминале команду:
```bash
unshare -r -m bash
```
* **Что произошло:** 
  - Флаг `-r` отображает текущего непривилегированного пользователя в виртуального суперпользователя `UID 0 (root)`.
  - Флаг `-m` создает изолированное пространство точек монтирования.

Проверьте:
```bash
whoami
# Вывод: root!

id
# Вывод: uid=0(root) gid=0(root) groups=0(root)
```

### 2.2. Отработка прав доступа в своей домашней папке:
Даже без виртуального root, внутри своего домашнего каталога (`~/`) вы являетесь **полным владельцем** и можете отрабатывать матрицу прав и ACL:

```bash
# Переходим в домашнюю папку
cd ~
mkdir -p my_lab/webapp my_lab/qa_reports

# Проверяем начальные права
ls -ld my_lab/webapp

# 1. Отработка восьмеричных прав:
chmod 700 my_lab/webapp          # Только вы имеете доступ (rwx------)
chmod 750 my_lab/webapp          # Вы - полный доступ, группа - чтение/вход

# 2. Отработка прав на конфиденциальный файл:
echo "DB_PASS=NoSudoSecret123" > my_lab/webapp/db_secrets.env
chmod 600 my_lab/webapp/db_secrets.env   # Чтение и запись только владельцу (rw-------)

# 3. Работа с POSIX ACL (не требует root для файлов, которыми вы владеете!):
setfacl -m u:nobody:r my_lab/webapp/db_secrets.env
getfacl my_lab/webapp/db_secrets.env
setfacl -x u:nobody my_lab/webapp/db_secrets.env

# 4. Проверка системной маски создания файлов:
umask
# Попробуйте изменить umask и создать файл:
umask 077
touch my_lab/webapp/secure_test.txt
ls -l my_lab/webapp/secure_test.txt   # Файл создался с правами -rw-------
umask 022                             # Возвращаем стандартное значение
```

### 2.3. Аудит системных файлов без root:
Файлы `/etc/passwd` и `/etc/group` открыты для чтения абсолютно всем:
```bash
# Анализ структуры учетных записей:
cat /etc/passwd | grep -E 'root|nobody|[1-9][0-9]{3}'

# Поиск системных пользователей без оболочки входа:
grep "nologin\|false" /etc/passwd | head -n 10

# Просмотр групп вашей системы:
cat /etc/group | head -n 15
```

---

## 🪟 ВАРИАНТ 3: Локальный Windows без прав Администратора

В ОС Windows обычный пользователь не может создать новую учетную запись в SAM, но имеет полные права на управление списками **NTFS DACL** и аудит собственной безопасности.

### 3.1. Аудит маркера доступа и прав текущего пользователя (CMD / PowerShell):
Запустите обычный PowerShell (без прав админа):

```powershell
# 1. Просмотр своего SID, привилегий и членства в группах:
whoami /all

# 2. Список локальных пользователей системы (чтение разрешено всем!):
Get-LocalUser | Select-Object Name, Enabled, SID, Description | Format-Table -AutoSize

# 3. Список групп безопасности системы:
Get-LocalGroup | Select-Object Name, Description | Format-Table -AutoSize

# 4. Просмотр участников группы «Пользователи» и «Администраторы»:
Get-LocalGroupMember -Group "Пользователи"
Get-LocalGroupMember -Group "Администраторы"
```

### 3.2. Отработка управления списками доступа NTFS (`icacls`) в своем профиле:
Вы являетесь владельцем каталога своего профиля (`$env:TEMP` или `C:\Users\ИмяПользователя`). Здесь вы можете настраивать любые права:

```powershell
# Создаем лабораторный каталог в своем профиле:
$LabDir = "$env:TEMP\WebAppProject"
New-Item -ItemType Directory -Path $LabDir -Force | Out-Null
Set-Location $LabDir

# Создаем тестовые файлы:
New-Item -ItemType File -Name "index.html" -Value "<h1>Web App</h1>" | Out-Null
New-Item -ItemType File -Name "db_secrets.json" -Value '{"password": "UserPass123"}' | Out-Null

# 1. Смотрим исходные права (унаследованные):
icacls .

# 2. Отключаем наследование и копируем текущие права:
icacls . /inheritance:d

# 3. Удаляем права группы "Прошедшие проверку" или стандартных "Пользователи":
icacls . /remove "Пользователи"
icacls . /remove "Users"

# 4. Выдаем себе полный доступ:
icacls . /grant "${env:USERNAME}:(OI)(CI)F"

# 5. Выдаем группе "Все" (Everyone) права ТОЛЬКО на чтение:
icacls . /grant "Все:(OI)(CI)R"
# или на англоязычной системе:
# icacls . /grant "Everyone:(OI)(CI)R"

# 6. Блокируем конфиденциальный файл (отключаем наследование и удаляем всех, кроме себя):
icacls ".\db_secrets.json" /inheritance:r
icacls ".\db_secrets.json" /grant "${env:USERNAME}:F"

# 7. Верификация:
icacls .
icacls ".\db_secrets.json"
```

---

## 🍏 ВАРИАНТ 4: macOS без пароля администратора

Если Mac в учебном классе заблокирован:
1. **Запустите GitHub Codespaces** (см. Вариант 1) — быстрее и проще всего.
2. Либо выполните аудит учетных записей Open Directory (чтение открыто):
   ```bash
   # Просмотр учетных записей macOS:
   dscl . -list /Users
   
   # Просмотр групп:
   dscl . -list /Groups
   
   # Просмотр своего членства в группах:
   id
   groups
   
   # Управление ACL в своей домашней директории:
   cd ~
   mkdir test_acl && cd test_acl
   touch secret.txt
   chmod 600 secret.txt
   ls -la secret.txt
   ```

---

## 📋 Что сдавать преподавателю, если делали без sudo?

Если у вас не было прав администратора, вы получаете полноценную оценку за работу, предоставив:
1. **Если работали в GitHub Codespaces:** скриншот терминала браузера с выводом скрипта `scripts/user_management_linux.sh` (оценивается на максимальный балл «5» наравне с обычным выполнением).
2. **Если работали в песочнице Windows без админа:** скриншот `whoami /all`, `Get-LocalUser` и вывод `icacls $env:TEMP\WebAppProject`.
3. **Если работали в песочнице Linux без sudo:** скриншот `cat /etc/passwd`, `ls -la ~/my_lab/webapp` и `getfacl ~/my_lab/webapp/db_secrets.env`.
