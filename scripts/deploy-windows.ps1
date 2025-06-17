# Erik-VPN Windows Deployment Script
# VLESS + Reality with 3X-UI Panel для Windows
# Version: 2.0

param(
    [switch]$SkipDocker,
    [switch]$Help
)

# Colors for output
$colors = @{
    Red    = "Red"
    Green  = "Green"
    Yellow = "Yellow"
    Blue   = "Blue"
    Purple = "Magenta"
    Cyan   = "Cyan"
}

function Write-ColoredOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $colors[$Color]
}

function Write-Banner {
    Write-ColoredOutput @"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                     ERIK-VPN v2.0 для Windows               ║
║                   VLESS + Reality Setup                     ║
║                                                              ║
║    🛡️  Максимальная стойкость к блокировкам                 ║
║    🚀  Высокая скорость подключения                         ║
║    🎛️  Удобная панель управления 3X-UI                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -Color "Purple"
}

function Show-Help {
    Write-ColoredOutput @"
Erik-VPN Windows Deployment Script

ИСПОЛЬЗОВАНИЕ:
    ./deploy-windows.ps1 [параметры]

ПАРАМЕТРЫ:
    -SkipDocker    Пропустить проверку Docker (если уже установлен)
    -Help          Показать эту справку

ПРИМЕРЫ:
    ./deploy-windows.ps1
    ./deploy-windows.ps1 -SkipDocker

ТРЕБОВАНИЯ:
    - Windows 10/11 Pro/Enterprise с Hyper-V
    - Docker Desktop для Windows
    - WSL2 (рекомендуется)
    - PowerShell 5.1+

"@ -Color "Cyan"
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Prerequisites {
    Write-ColoredOutput "🔍 Проверка системных требований..." -Color "Blue"

    # Check Windows version
    $winVersion = [System.Environment]::OSVersion.Version
    if ($winVersion.Major -lt 10) {
        Write-ColoredOutput "❌ Требуется Windows 10 или выше" -Color "Red"
        exit 1
    }

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-ColoredOutput "❌ Требуется PowerShell 5.1 или выше" -Color "Red"
        exit 1
    }

    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ColoredOutput "⚠️  Рекомендуется запускать как администратор для полной функциональности" -Color "Yellow"
    }

    Write-ColoredOutput "✅ Системные требования проверены" -Color "Green"
}

function Test-Docker {
    if ($SkipDocker) {
        Write-ColoredOutput "⏭️  Проверка Docker пропущена" -Color "Yellow"
        return
    }

    Write-ColoredOutput "🐳 Проверка Docker..." -Color "Blue"

    # Check if Docker is installed
    try {
        $dockerVersion = docker --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredOutput "✅ Docker найден: $dockerVersion" -Color "Green"
        } else {
            throw "Docker не найден"
        }
    } catch {
        Write-ColoredOutput @"
❌ Docker не установлен или не найден в PATH

УСТАНОВИТЕ DOCKER DESKTOP:
1. Скачайте с https://www.docker.com/products/docker-desktop
2. Установите Docker Desktop
3. Включите WSL2 backend (рекомендуется)
4. Запустите Docker Desktop
5. Дождитесь полной загрузки
6. Повторите запуск скрипта

"@ -Color "Red"
        exit 1
    }

    # Check if Docker is running
    try {
        docker info >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredOutput "✅ Docker запущен и работает" -Color "Green"
        } else {
            throw "Docker не запущен"
        }
    } catch {
        Write-ColoredOutput @"
❌ Docker не запущен

ЗАПУСТИТЕ DOCKER:
1. Откройте Docker Desktop
2. Дождитесь надписи "Docker Desktop is running"
3. Повторите запуск скрипта

"@ -Color "Red"
        exit 1
    }

    # Check Docker Compose
    try {
        $composeVersion = docker-compose --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ColoredOutput "✅ Docker Compose найден: $composeVersion" -Color "Green"
        } else {
            # Try docker compose (newer syntax)
            docker compose version >$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColoredOutput "✅ Docker Compose (v2) найден" -Color "Green"
            } else {
                throw "Docker Compose не найден"
            }
        }
    } catch {
        Write-ColoredOutput "❌ Docker Compose не найден. Обновите Docker Desktop до последней версии." -Color "Red"
        exit 1
    }
}

function Initialize-Project {
    Write-ColoredOutput "📁 Инициализация проекта..." -Color "Blue"

    $projectRoot = Split-Path -Parent $PSScriptRoot
    Set-Location $projectRoot

    # Create necessary directories
    $directories = @(
        "data\3x-ui",
        "certs",
        "logs\xray",
        "logs\nginx",
        "nginx\conf.d",
        "monitoring",
        "monitoring\grafana\dashboards",
        "monitoring\grafana\datasources",
        "fail2ban"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColoredOutput "📁 Создан каталог: $dir" -Color "Cyan"
        }
    }

    Write-ColoredOutput "✅ Структура каталогов создана" -Color "Green"
}

function Initialize-Environment {
    Write-ColoredOutput "⚙️  Настройка конфигурации..." -Color "Blue"

    # Copy .env file if it doesn't exist
    if (-not (Test-Path ".env")) {
        if (Test-Path "env.example") {
            Copy-Item "env.example" ".env"
            Write-ColoredOutput "📄 Создан файл .env из env.example" -Color "Cyan"
        } else {
            Write-ColoredOutput "❌ Файл env.example не найден" -Color "Red"
            exit 1
        }
    }

    # Generate random passwords for Windows
    $adminPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    $sessionSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $grafanaPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})

    # Update .env file
    $envContent = Get-Content ".env"
    $envContent = $envContent -replace "your-secure-password-here", $adminPassword
    $envContent = $envContent -replace "your-random-session-secret-here", $sessionSecret
    $envContent = $envContent -replace "grafana-admin-password", $grafanaPassword
    $envContent = $envContent -replace "your-server-ip-or-domain.com", "localhost"
    $envContent | Set-Content ".env"

    Write-ColoredOutput "✅ Конфигурация настроена" -Color "Green"
    Write-ColoredOutput "📋 Сохраните эти учетные данные:" -Color "Yellow"
    Write-ColoredOutput "   Администратор 3X-UI: admin / $adminPassword" -Color "Cyan"
    Write-ColoredOutput "   Администратор Grafana: admin / $grafanaPassword" -Color "Cyan"

    # Save credentials to file
    $credentialsPath = "logs\credentials.txt"
    @"
Erik-VPN Учетные данные
Дата создания: $(Get-Date)

3X-UI Panel: http://localhost:2053
Логин: admin
Пароль: $adminPassword

Grafana: http://localhost:3000
Логин: admin
Пароль: $grafanaPassword

Сессионный ключ: $sessionSecret
"@ | Out-File -FilePath $credentialsPath -Encoding UTF8

    Write-ColoredOutput "💾 Учетные данные сохранены в $credentialsPath" -Color "Green"
}

function Start-Services {
    Write-ColoredOutput "🚀 Запуск Erik-VPN сервисов..." -Color "Blue"

    # Check which docker-compose command to use
    $dockerComposeCmd = "docker-compose"
    try {
        docker-compose --version >$null 2>&1
        if ($LASTEXITCODE -ne 0) {
            $dockerComposeCmd = "docker compose"
        }
    } catch {
        $dockerComposeCmd = "docker compose"
    }

    # Pull latest images
    Write-ColoredOutput "📥 Загрузка Docker образов..." -Color "Cyan"
    Invoke-Expression "$dockerComposeCmd pull xray-ui"

    # Start services
    Write-ColoredOutput "▶️  Запуск контейнеров..." -Color "Cyan"
    Invoke-Expression "$dockerComposeCmd up -d xray-ui"

    if ($LASTEXITCODE -eq 0) {
        Write-ColoredOutput "✅ Сервисы запущены успешно" -Color "Green"
    } else {
        Write-ColoredOutput "❌ Ошибка при запуске сервисов" -Color "Red"
        Invoke-Expression "$dockerComposeCmd logs"
        exit 1
    }

    # Wait for services to start
    Write-ColoredOutput "⏳ Ожидание готовности сервисов (30 секунд)..." -Color "Blue"
    Start-Sleep -Seconds 30

    # Test if 3X-UI is accessible
    for ($i = 1; $i -le 10; $i++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:2053" -TimeoutSec 5 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-ColoredOutput "✅ 3X-UI панель доступна" -Color "Green"
                break
            }
        } catch {
            if ($i -eq 10) {
                Write-ColoredOutput "⚠️  3X-UI панель может быть недоступна. Проверьте логи." -Color "Yellow"
            } else {
                Start-Sleep -Seconds 3
            }
        }
    }
}

function Show-FinalInfo {
    $envContent = Get-Content ".env"
    $adminPassword = ($envContent | Where-Object { $_ -match "ADMIN_PASSWORD=" }) -replace "ADMIN_PASSWORD=", ""

    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "🎉 Erik-VPN успешно развернут на Windows!" -Color "Green"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "╔══════════════════════════════════════════════════════════════╗" -Color "Purple"
    Write-ColoredOutput "║                    ИНФОРМАЦИЯ О ДОСТУПЕ                     ║" -Color "Purple"
    Write-ColoredOutput "╚══════════════════════════════════════════════════════════════╝" -Color "Purple"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "🎛️  Панель управления 3X-UI:" -Color "Cyan"
    Write-ColoredOutput "   URL: http://localhost:2053" -Color "Green"
    Write-ColoredOutput "   Логин: admin" -Color "Green"
    Write-ColoredOutput "   Пароль: $adminPassword" -Color "Green"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "📱 Поддерживаемые клиенты:" -Color "Cyan"
    Write-ColoredOutput "   Android: Hiddify, v2rayNG, Fair VPN" -Color "Green"
    Write-ColoredOutput "   iOS: FoXray, Shadowrocket, Hiddify" -Color "Green"
    Write-ColoredOutput "   Windows: Hiddify, v2rayN, Qv2ray" -Color "Green"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "🔧 Полезные команды:" -Color "Cyan"
    Write-ColoredOutput "   Перезапуск: docker-compose restart" -Color "Green"
    Write-ColoredOutput "   Логи: docker-compose logs -f" -Color "Green"
    Write-ColoredOutput "   Остановка: docker-compose down" -Color "Green"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "⚠️  Следующие шаги:" -Color "Yellow"
    Write-ColoredOutput "   1. Откройте браузер и перейдите к http://localhost:2053" -Color "White"
    Write-ColoredOutput "   2. Войдите используя admin / $adminPassword" -Color "White"
    Write-ColoredOutput "   3. Создайте конфигурацию VLESS + Reality" -Color "White"
    Write-ColoredOutput "   4. Настройте клиентские приложения" -Color "White"
    Write-ColoredOutput "" -Color "White"
    Write-ColoredOutput "💾 Учетные данные сохранены в: logs\credentials.txt" -Color "Purple"
    Write-ColoredOutput "📖 Документация: .\docs\" -Color "Purple"
    Write-ColoredOutput "" -Color "White"
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Banner

try {
    Test-Prerequisites
    Test-Docker
    Initialize-Project
    Initialize-Environment
    Start-Services
    Show-FinalInfo
} catch {
    Write-ColoredOutput "❌ Ошибка выполнения: $_" -Color "Red"
    exit 1
}

Write-ColoredOutput "✅ Развертывание Erik-VPN на Windows завершено успешно!" -Color "Green"
