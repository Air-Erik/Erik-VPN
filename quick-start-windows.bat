@echo off
title Erik-VPN Quick Start для Windows

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                   ERIK-VPN QUICK START                      ║
echo ║                     для Windows                             ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo [1/4] Проверка Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker не найден! Установите Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo ✅ Docker найден

echo.
echo [2/4] Создание конфигурации...
if not exist .env (
    copy env.example .env >nul 2>&1
    echo ✅ Создан файл .env
) else (
    echo ✅ Файл .env уже существует
)

echo.
echo [3/4] Создание необходимых папок...
if not exist data mkdir data
if not exist data\3x-ui mkdir data\3x-ui
if not exist logs mkdir logs
if not exist logs\xray mkdir logs\xray
if not exist certs mkdir certs
echo ✅ Папки созданы

echo.
echo [4/4] Запуск Erik-VPN...
docker-compose -f docker-compose.windows.yml up -d xray-ui
if errorlevel 1 (
    echo ❌ Ошибка запуска! Проверьте логи: docker-compose -f docker-compose.windows.yml logs
    pause
    exit /b 1
)

echo.
echo ✅ Erik-VPN успешно запущен!
echo.
echo 🎛️  Панель управления: http://localhost:2053
echo 👤 Логин: admin
echo 🔑 Пароль: admin123456
echo.
echo 💡 Для остановки: docker-compose -f docker-compose.windows.yml down
echo 📋 Для просмотра логов: docker-compose -f docker-compose.windows.yml logs -f
echo.
echo 📖 Подробная документация: docs\windows-setup.md
echo.

pause
