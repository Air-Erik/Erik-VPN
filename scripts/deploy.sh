#!/bin/bash

# Erik-VPN Deployment Script
# VLESS + Reality with 3X-UI Panel
# Version: 2.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/deploy.log"

# Create logs directory
mkdir -p "$PROJECT_DIR/logs"

# Logging function
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_banner() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                       ERIK-VPN v2.0                         ║
║                   VLESS + Reality Setup                     ║
║                                                              ║
║    🛡️  Максимальная стойкость к блокировкам                 ║
║    🚀  Высокая скорость подключения                         ║
║    🎛️  Удобная панель управления 3X-UI                     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log "${RED}⚠️  Не запускайте скрипт под root! Используйте обычного пользователя с sudo.${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt >/dev/null 2>&1; then
            OS="ubuntu"
            PACKAGE_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            OS="centos"
            PACKAGE_MANAGER="yum"
        elif command -v dnf >/dev/null 2>&1; then
            OS="fedora"
            PACKAGE_MANAGER="dnf"
        else
            log "${RED}❌ Неподдерживаемая Linux система${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        PACKAGE_MANAGER="brew"
    else
        log "${RED}❌ Неподдерживаемая операционная система: $OSTYPE${NC}"
        exit 1
    fi

    log "${GREEN}✅ Обнаружена ОС: $OS${NC}"
}

# Check system requirements
check_requirements() {
    log "${BLUE}🔍 Проверка системных требований...${NC}"

    # Check memory
    if [[ "$OS" != "macos" ]]; then
        total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        if [ "$total_mem" -lt 512 ]; then
            log "${YELLOW}⚠️  Предупреждение: Рекомендуется минимум 512MB RAM (обнаружено: ${total_mem}MB)${NC}"
        fi
    fi

    # Check disk space
    available_space=$(df "$PROJECT_DIR" | awk 'NR==2 {print $4}')
    if [ "$available_space" -lt 1048576 ]; then  # 1GB in KB
        log "${YELLOW}⚠️  Предупреждение: Рекомендуется минимум 1GB свободного места${NC}"
    fi

    log "${GREEN}✅ Системные требования проверены${NC}"
}

# Install Docker and Docker Compose
install_docker() {
    if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
        log "${GREEN}✅ Docker уже установлен${NC}"
        return 0
    fi

    log "${BLUE}🐳 Установка Docker...${NC}"

    case $OS in
        ubuntu)
            # Remove old versions
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

            # Update packages
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg lsb-release

            # Add Docker GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Add user to docker group
            sudo usermod -aG docker "$USER"
            ;;
        centos|fedora)
            # Remove old versions
            sudo $PACKAGE_MANAGER remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true

            # Install required packages
            sudo $PACKAGE_MANAGER install -y yum-utils

            # Add Docker repository
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

            # Install Docker
            sudo $PACKAGE_MANAGER install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Enable and start Docker
            sudo systemctl enable docker
            sudo systemctl start docker

            # Add user to docker group
            sudo usermod -aG docker "$USER"
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                log "${RED}❌ Homebrew не установлен. Установите его с https://brew.sh/${NC}"
                exit 1
            fi

            # Install Docker Desktop for Mac
            brew install --cask docker
            log "${YELLOW}⚠️  Запустите Docker Desktop и дождитесь его полной загрузки${NC}"
            ;;
    esac

    log "${GREEN}✅ Docker установлен${NC}"
}

# Setup directories
setup_directories() {
    log "${BLUE}📁 Создание структуры каталогов...${NC}"

    cd "$PROJECT_DIR"

    # Create necessary directories
    directories=(
        "data/3x-ui"
        "certs"
        "logs/xray"
        "logs/nginx"
        "nginx/conf.d"
        "monitoring"
        "monitoring/grafana/dashboards"
        "monitoring/grafana/datasources"
        "fail2ban"
    )

    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log "📁 Создан каталог: $dir"
    done

    # Set proper permissions
    chmod 755 data/3x-ui
    chmod 755 logs

    log "${GREEN}✅ Структура каталогов создана${NC}"
}

# Generate configuration files
generate_configs() {
    log "${BLUE}⚙️  Создание конфигурационных файлов...${NC}"

    cd "$PROJECT_DIR"

    # Copy environment file if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            log "📄 Создан файл .env из env.example"
        else
            log "${RED}❌ Файл env.example не найден${NC}"
            exit 1
        fi
    fi

    # Generate random passwords and secrets
    if command -v openssl >/dev/null 2>&1; then
        ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/")
        SESSION_SECRET=$(openssl rand -hex 32)
        GRAFANA_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/")

        # Update .env file with generated values
        sed -i.bak "s/your-secure-password-here/$ADMIN_PASSWORD/" .env
        sed -i.bak "s/your-random-session-secret-here/$SESSION_SECRET/" .env
        sed -i.bak "s/grafana-admin-password/$GRAFANA_PASSWORD/" .env

        log "${GREEN}✅ Сгенерированы случайные пароли${NC}"
        log "${YELLOW}📋 Сохраните эти учетные данные:${NC}"
        log "${CYAN}   Администратор 3X-UI: admin / $ADMIN_PASSWORD${NC}"
        log "${CYAN}   Администратор Grafana: admin / $GRAFANA_PASSWORD${NC}"
    fi

    # Create basic nginx config
    cat > nginx/nginx.conf << 'EOF'
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    log "${GREEN}✅ Конфигурационные файлы созданы${NC}"
}

# Detect server IP
detect_server_ip() {
    log "${BLUE}🌐 Определение IP-адреса сервера...${NC}"

    # Try different methods to get public IP
    SERVER_IP=""

    # Method 1: ip route (for local development)
    if [[ -z "$SERVER_IP" ]]; then
        SERVER_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $(NF-2); exit}' 2>/dev/null || true)
    fi

    # Method 2: hostname -I (fallback)
    if [[ -z "$SERVER_IP" ]]; then
        SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi

    # Method 3: ifconfig (fallback)
    if [[ -z "$SERVER_IP" ]] && command -v ifconfig >/dev/null 2>&1; then
        SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    fi

    if [[ -n "$SERVER_IP" ]]; then
        # Update .env file with detected IP
        sed -i.bak "s/your-server-ip-or-domain.com/$SERVER_IP/" .env
        log "${GREEN}✅ Обнаружен IP-адрес: $SERVER_IP${NC}"
    else
        log "${YELLOW}⚠️  Не удалось автоматически определить IP. Укажите его вручную в файле .env${NC}"
    fi
}

# Start services
start_services() {
    log "${BLUE}🚀 Запуск Erik-VPN сервисов...${NC}"

    cd "$PROJECT_DIR"

    # Pull latest images
    docker-compose pull

    # Start services
    docker-compose up -d xray-ui

    # Wait for services to start
    log "${BLUE}⏳ Ожидание запуска сервисов (30 секунд)...${NC}"
    sleep 30

    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        log "${GREEN}✅ Сервисы Erik-VPN успешно запущены${NC}"
    else
        log "${RED}❌ Ошибка при запуске сервисов${NC}"
        docker-compose logs
        exit 1
    fi
}

# Setup firewall rules
setup_firewall() {
    if [[ "$OS" == "macos" ]]; then
        log "${YELLOW}⚠️  macOS: Настройка брандмауэра пропущена${NC}"
        return 0
    fi

    log "${BLUE}🔥 Настройка брандмауэра...${NC}"

    # Install and configure UFW (Ubuntu/Debian)
    if command -v ufw >/dev/null 2>&1; then
        sudo ufw --force enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing

        # Allow SSH
        sudo ufw allow ssh

        # Allow 3X-UI panel
        sudo ufw allow 2053/tcp comment "3X-UI Panel"

        # Allow Xray ports
        sudo ufw allow 443/tcp comment "VLESS Reality"
        sudo ufw allow 80/tcp comment "VMess"
        sudo ufw allow 8080/tcp comment "VLESS Reality Alt"
        sudo ufw allow 8443/tcp comment "Trojan"

        log "${GREEN}✅ UFW настроен${NC}"

    # Configure firewalld (CentOS/RHEL/Fedora)
    elif command -v firewall-cmd >/dev/null 2>&1; then
        sudo systemctl enable firewalld
        sudo systemctl start firewalld

        # Allow services
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-port=2053/tcp
        sudo firewall-cmd --permanent --add-port=443/tcp
        sudo firewall-cmd --permanent --add-port=80/tcp
        sudo firewall-cmd --permanent --add-port=8080/tcp
        sudo firewall-cmd --permanent --add-port=8443/tcp

        sudo firewall-cmd --reload

        log "${GREEN}✅ Firewalld настроен${NC}"
    else
        log "${YELLOW}⚠️  Брандмауэр не обнаружен. Настройте вручную порты: 2053, 443, 80, 8080, 8443${NC}"
    fi
}

# Print final information
print_final_info() {
    log "${GREEN}🎉 Erik-VPN успешно развернут!${NC}"
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    ИНФОРМАЦИЯ О ДОСТУПЕ                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🎛️  Панель управления 3X-UI:${NC}"
    echo -e "   URL: ${GREEN}http://$SERVER_IP:2053${NC}"
    echo -e "   Логин: ${GREEN}admin${NC}"
    echo -e "   Пароль: ${GREEN}$(grep ADMIN_PASSWORD .env | cut -d'=' -f2)${NC}"
    echo
    echo -e "${CYAN}📱 Поддерживаемые клиенты:${NC}"
    echo -e "   Android: ${GREEN}Hiddify, v2rayNG, Fair VPN${NC}"
    echo -e "   iOS: ${GREEN}FoXray, Shadowrocket, Hiddify${NC}"
    echo -e "   Windows: ${GREEN}Hiddify, v2rayN, Qv2ray${NC}"
    echo -e "   macOS: ${GREEN}Hiddify, ClashX Pro, Qv2ray${NC}"
    echo -e "   Linux: ${GREEN}Hiddify, v2ray/Xray-core${NC}"
    echo
    echo -e "${CYAN}🔧 Полезные команды:${NC}"
    echo -e "   Перезапуск: ${GREEN}docker-compose restart${NC}"
    echo -e "   Логи: ${GREEN}docker-compose logs -f${NC}"
    echo -e "   Остановка: ${GREEN}docker-compose down${NC}"
    echo -e "   Обновление: ${GREEN}docker-compose pull && docker-compose up -d${NC}"
    echo
    echo -e "${YELLOW}⚠️  Следующие шаги:${NC}"
    echo -e "   1. Войдите в панель управления 3X-UI"
    echo -e "   2. Создайте конфигурацию VLESS + Reality"
    echo -e "   3. Настройте клиентские приложения"
    echo -e "   4. Проверьте подключение"
    echo
    echo -e "${PURPLE}📖 Документация: ${GREEN}./docs/${NC}"
    echo -e "${PURPLE}🐛 Логи развертывания: ${GREEN}$LOG_FILE${NC}"
    echo
}

# Main function
main() {
    print_banner

    log "${BLUE}🚀 Начало развертывания Erik-VPN...${NC}"

    check_root
    detect_os
    check_requirements
    install_docker
    setup_directories
    generate_configs
    detect_server_ip
    start_services
    setup_firewall
    print_final_info

    log "${GREEN}✅ Развертывание Erik-VPN завершено успешно!${NC}"
}

# Run main function
main "$@"
