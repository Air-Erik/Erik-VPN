# Erik-VPN на Windows - Подробная инструкция

🪟 **Установка и настройка Erik-VPN на Windows 10/11**

## 🔧 Системные требования

### Минимальные требования:
- **ОС**: Windows 10 Build 19041+ или Windows 11
- **Версия**: Pro, Enterprise или Education (для Hyper-V)
- **RAM**: 4GB+ (рекомендуется 8GB)
- **Диск**: 10GB свободного места
- **Процессор**: с поддержкой виртуализации (VT-x/AMD-V)

### Требуемое ПО:
- **Docker Desktop для Windows**
- **PowerShell 5.1+** (встроен в Windows)
- **Git для Windows** (опционально)

## 🚀 Способы установки

### Способ 1: PowerShell скрипт (рекомендуется)

1. **Скачайте проект:**
   ```powershell
   git clone https://github.com/your-username/Erik-VPN.git
   cd Erik-VPN
   ```

2. **Установите Docker Desktop** (если не установлен):
   - Скачайте с [docker.com](https://www.docker.com/products/docker-desktop)
   - Установите с включением WSL2 backend
   - Перезагрузите компьютер
   - Запустите Docker Desktop и дождитесь готовности

3. **Запустите PowerShell как администратор** и выполните:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\scripts\deploy-windows.ps1
   ```

4. **Дождитесь завершения** установки (~5-10 минут)

### Способ 2: WSL2 + Bash скрипт

1. **Установите WSL2:**
   ```powershell
   wsl --install
   ```

2. **Перезагрузите** компьютер

3. **Откройте Ubuntu** из меню Пуск

4. **В WSL2 выполните:**
   ```bash
   git clone https://github.com/your-username/Erik-VPN.git
   cd Erik-VPN
   ./scripts/deploy.sh
   ```

### Способ 3: Docker Compose вручную

1. **Создайте .env файл:**
   ```powershell
   copy env.example .env
   ```

2. **Отредактируйте .env** в любом текстовом редакторе:
   - Замените `your-server-ip-or-domain.com` на `localhost`
   - Установите безопасные пароли

3. **Запустите Docker:**
   ```powershell
   docker-compose up -d xray-ui
   ```

## 🛠️ Устранение проблем

### ❌ Проблема: "Docker не найден"

**Решение:**
1. Убедитесь что Docker Desktop установлен
2. Запустите Docker Desktop
3. Дождитесь появления "Docker Desktop is running"
4. Перезапустите PowerShell/CMD

### ❌ Проблема: "Execution Policy"

**Решение:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ Проблема: "Hyper-V не поддерживается"

**Решение:**
1. Убедитесь что у вас Windows 10/11 Pro/Enterprise
2. Включите Hyper-V в "Включение или отключение компонентов Windows"
3. Включите виртуализацию в BIOS
4. Перезагрузите компьютер

### ❌ Проблема: "WSL2 не установлен"

**Решение:**
```powershell
# Запустите как администратор
wsl --install
# Перезагрузите компьютер
wsl --set-default-version 2
```

### ❌ Проблема: "Порт 2053 занят"

**Решение:**
```powershell
# Найдите процесс на порту
netstat -ano | findstr :2053
# Остановите процесс (замените PID)
taskkill /F /PID [PID]
```

### ❌ Проблема: "Недостаточно RAM"

**Решение:**
1. Закройте ненужные приложения
2. В Docker Desktop → Settings → Resources → Memory установите 2GB+
3. Перезапустите Docker Desktop

## 🔧 Настройка после установки

### 1. Доступ к панели управления

- **URL**: `http://localhost:2053`
- **Логин**: `admin`
- **Пароль**: указан в файле `logs\credentials.txt`

### 2. Создание конфигурации VLESS + Reality

1. Войдите в панель 3X-UI
2. Перейдите в раздел "Inbounds"
3. Нажмите "Add Inbound"
4. Выберите протокол **VLESS**
5. Настройте параметры:
   - **Port**: 443
   - **Transport**: TCP
   - **Security**: Reality
   - **Dest**: microsoft.com:443
   - **SNI**: microsoft.com

### 3. Настройка клиентов

**Для Windows:**
- Скачайте [Hiddify](https://github.com/hiddify/hiddify-next/releases) или [v2rayN](https://github.com/2dust/v2rayN/releases)
- Импортируйте конфигурацию из панели 3X-UI

**Для Android:**
- Установите Hiddify или v2rayNG из Google Play
- Отсканируйте QR-код или вставьте ссылку конфигурации

## 📊 Мониторинг и управление

### Полезные команды PowerShell:

```powershell
# Статус контейнеров
docker-compose ps

# Логи в реальном времени
docker-compose logs -f xray-ui

# Перезапуск сервиса
docker-compose restart xray-ui

# Остановка всех сервисов
docker-compose down

# Обновление образов
docker-compose pull
docker-compose up -d

# Очистка неиспользуемых образов
docker system prune -a
```

### Запуск дополнительных сервисов:

```powershell
# Запуск с мониторингом
docker-compose --profile monitoring up -d

# Доступ к Grafana
# http://localhost:3000 (admin/admin)
```

## 🔒 Безопасность на Windows

### Рекомендации:

1. **Обновите пароли** в файле `.env`
2. **Включите Windows Defender** Firewall
3. **Используйте антивирус** (встроенный Windows Defender достаточно)
4. **Регулярно обновляйте** Docker Desktop и образы

### Настройка Firewall:

1. Откройте **Windows Defender Firewall**
2. Разрешите **Docker Desktop** в исключениях
3. Убедитесь что порты 2053, 443, 80 разрешены для локальных подключений

## 📱 Тестирование подключения

### Локальное тестирование:

1. **Создайте конфигурацию** в панели 3X-UI
2. **Скопируйте ссылку** или QR-код
3. **Настройте клиент** на том же компьютере
4. **Проверьте** доступ к заблокированным сайтам

### Проверка с мобильного:

1. **Подключите телефон** к той же Wi-Fi сети
2. **Используйте IP компьютера** вместо localhost
3. **Импортируйте конфигурацию** в мобильное приложение

## 🔄 Автоматические обновления

Создайте файл `update.ps1`:

```powershell
# Обновление Erik-VPN
Write-Host "Обновление Erik-VPN..." -ForegroundColor Green

# Обновление кода
git pull origin main

# Обновление Docker образов
docker-compose pull

# Перезапуск сервисов
docker-compose up -d

Write-Host "Обновление завершено!" -ForegroundColor Green
```

Запускайте еженедельно для получения обновлений.

## 📞 Поддержка

### Часто задаваемые вопросы:

**Q: Можно ли использовать на Windows Home?**
A: Да, но потребуется Docker Toolbox вместо Docker Desktop

**Q: Влияет ли на производительность Windows?**
A: Минимально. Docker Desktop использует 1-2GB RAM в фоне

**Q: Можно ли запускать несколько конфигураций?**
A: Да, создайте несколько Inbound в панели с разными портами

**Q: Как изменить порт панели управления?**
A: Измените `PANEL_PORT` в файле `.env` и перезапустите

### Получение помощи:

1. **Проверьте логи**: `docker-compose logs -f`
2. **Изучите документацию** в папке `docs/`
3. **Создайте Issue** в GitHub репозитории
4. **Присоединитесь** к сообществу в Telegram

---

*Документация для Erik-VPN v2.0 на Windows*
