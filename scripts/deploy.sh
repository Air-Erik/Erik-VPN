#!/bin/bash

# =================================================================
# ERIK-VPN AUTOMATED DEPLOYMENT SCRIPT
# =================================================================
# Автоматическое развертывание VPN сервера одной командой

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода цветного текста
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав суперпользователя
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Скрипт запущен от имени root. Рекомендуется использовать sudo."
    fi
}

# Определение ОС
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Не удалось определить операционную систему"
        exit 1
    fi
    print_status "Обнаружена ОС: $OS $VER"
}

# Установка Docker
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker уже установлен"
        return
    fi

    print_status "Установка Docker..."

    case "$OS" in
        "Ubuntu"|"Debian GNU/Linux")
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux")
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *)
            print_error "Неподдерживаемая ОС: $OS"
            print_status "Попробуйте установить Docker вручную: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac

    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER

    print_success "Docker установлен успешно"
}

# Установка Docker Compose (если нет)
install_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        print_success "Docker Compose уже установлен"
        return
    fi

    print_status "Установка Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose установлен"
}

# Получение внешнего IP
get_external_ip() {
    EXTERNAL_IP=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || curl -s http://checkip.amazonaws.com 2>/dev/null || echo "")
    if [[ -z "$EXTERNAL_IP" ]]; then
        print_warning "Не удалось автоматически определить внешний IP"
        read -p "Введите IP-адрес или домен вашего сервера: " EXTERNAL_IP
    else
        print_status "Обнаружен внешний IP: $EXTERNAL_IP"
        read -p "Использовать этот IP? (y/n) [y]: " -r confirm
        confirm=${confirm:-y}
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            read -p "Введите IP-адрес или домен вашего сервера: " EXTERNAL_IP
        fi
    fi
}

# Настройка конфигурации
setup_config() {
    print_status "Настройка конфигурации..."

    if [[ ! -f .env ]]; then
        cp env.example .env
        print_status "Создан файл .env из примера"
    fi

    # Обновление IP в конфигурации
    sed -i "s/WG_HOST=your-server-ip/WG_HOST=$EXTERNAL_IP/g" .env

    # Генерация случайного пароля для админ-панели
    ADMIN_PASSWORD=$(openssl rand -base64 12 2>/dev/null || head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)
    sed -i "s/ADMIN_PASSWORD=your-secure-password/ADMIN_PASSWORD=$ADMIN_PASSWORD/g" .env

    print_success "Конфигурация настроена"
    print_status "Пароль для веб-интерфейса: $ADMIN_PASSWORD"
}

# Создание необходимых папок
create_directories() {
    print_status "Создание директорий..."
    mkdir -p data logs monitoring/grafana/provisioning
    sudo chown -R $USER:$USER data logs
    print_success "Директории созданы"
}

# Настройка файрвола
configure_firewall() {
    print_status "Настройка файрвола..."

    if command -v ufw &> /dev/null; then
        sudo ufw allow 51820/udp comment "WireGuard"
        sudo ufw allow 51821/tcp comment "WireGuard Web UI"
        print_success "UFW настроен"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-port=51820/udp
        sudo firewall-cmd --permanent --add-port=51821/tcp
        sudo firewall-cmd --reload
        print_success "Firewalld настроен"
    else
        print_warning "Файрвол не обнаружен. Убедитесь, что порты 51820/udp и 51821/tcp открыты"
    fi
}

# Включение IP forwarding
enable_ip_forwarding() {
    print_status "Включение IP forwarding..."
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    print_success "IP forwarding включен"
}

# Запуск контейнеров
start_containers() {
    print_status "Запуск VPN сервера..."
    docker-compose up -d
    print_success "VPN сервер запущен!"
}

# Проверка статуса
check_status() {
    print_status "Проверка статуса..."
    sleep 5

    if docker ps | grep -q erik-vpn; then
        print_success "Контейнер erik-vpn работает"
    else
        print_error "Проблема с запуском контейнера"
        docker-compose logs
        exit 1
    fi
}

# Показ итоговой информации
show_final_info() {
    print_success "🎉 Развертывание завершено успешно!"
    echo
    echo "==================================================================="
    echo "📋 ИНФОРМАЦИЯ О ВАШЕМ VPN СЕРВЕРЕ"
    echo "==================================================================="
    echo "🌐 Веб-интерфейс: http://$EXTERNAL_IP:51821"
    echo "🔑 Пароль админа: $ADMIN_PASSWORD"
    echo "🔌 WireGuard порт: 51820/udp"
    echo "📊 Веб-интерфейс порт: 51821/tcp"
    echo
    echo "==================================================================="
    echo "📱 СЛЕДУЮЩИЕ ШАГИ"
    echo "==================================================================="
    echo "1. Откройте веб-интерфейс в браузере"
    echo "2. Войдите с паролем: $ADMIN_PASSWORD"
    echo "3. Создайте новых пользователей"
    echo "4. Скачайте конфигурации для устройств"
    echo "5. Установите WireGuard клиенты на устройства"
    echo
    echo "==================================================================="
    echo "📚 ПОЛЕЗНЫЕ КОМАНДЫ"
    echo "==================================================================="
    echo "• Просмотр логов: docker-compose logs -f"
    echo "• Остановка сервера: docker-compose down"
    echo "• Запуск сервера: docker-compose up -d"
    echo "• Перезапуск: docker-compose restart"
    echo
    print_warning "Сохраните пароль администратора в безопасном месте!"
}

# Основная функция
main() {
    echo "==================================================================="
    echo "🚀 ERIK-VPN AUTOMATIC DEPLOYMENT"
    echo "==================================================================="
    echo

    check_root
    detect_os
    install_docker
    install_docker_compose
    get_external_ip
    setup_config
    create_directories
    configure_firewall
    enable_ip_forwarding
    start_containers
    check_status
    show_final_info
}

# Запуск скрипта
main "$@"
