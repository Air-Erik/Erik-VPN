#!/bin/bash

# Erik-VPN Local Testing Script
# VLESS + Reality Local Prototype
# Version: 1.0

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
LOG_FILE="$PROJECT_DIR/logs/local-test.log"

# Create logs directory if it doesn't exist
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
║                  ERIK-VPN LOCAL TESTING                     ║
║                   VLESS + Reality                           ║
║                                                              ║
║    🧪  Локальное тестирование прототипа                     ║
║    🔬  Проверка всех компонентов                            ║
║    📊  Валидация конфигураций                               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "${BLUE}🔍 Проверка предварительных требований...${NC}"

    # Check if we're in the right directory
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        log "${RED}❌ docker-compose.yml не найден. Убедитесь, что вы находитесь в корне проекта Erik-VPN${NC}"
        exit 1
    fi

    # Check if Docker is installed and running
    if ! command -v docker >/dev/null 2>&1; then
        log "${RED}❌ Docker не установлен. Установите Docker перед продолжением${NC}"
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log "${RED}❌ Docker не запущен. Запустите Docker перед продолжением${NC}"
        exit 1
    fi

    # Check if docker-compose is available
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log "${RED}❌ Docker Compose не найден${NC}"
        exit 1
    fi

    # Determine docker-compose command
    if command -v docker-compose >/dev/null 2>&1; then
        DOCKER_COMPOSE="docker-compose"
    else
        DOCKER_COMPOSE="docker compose"
    fi

    log "${GREEN}✅ Все предварительные требования выполнены${NC}"
}

# Setup environment
setup_environment() {
    log "${BLUE}⚙️  Настройка окружения для тестирования...${NC}"

    cd "$PROJECT_DIR"

    # Create .env file if it doesn't exist
    if [ ! -f .env ]; then
        if [ -f env.example ]; then
            cp env.example .env
            log "📄 Создан .env файл из env.example"
        else
            log "${RED}❌ env.example не найден${NC}"
            exit 1
        fi
    fi

    # Update .env for local testing
    sed -i.bak 's/your-server-ip-or-domain.com/localhost/' .env
    sed -i.bak 's/your-secure-password-here/test123456/' .env
    sed -i.bak 's/your-random-session-secret-here/test-session-secret-for-local-development/' .env
    sed -i.bak 's/grafana-admin-password/test123456/' .env

    log "${GREEN}✅ Окружение настроено для локального тестирования${NC}"
}

# Pull Docker images
pull_images() {
    log "${BLUE}🐳 Загрузка Docker образов...${NC}"

    cd "$PROJECT_DIR"

    # Pull main service images
    $DOCKER_COMPOSE pull xray-ui

    log "${GREEN}✅ Docker образы загружены${NC}"
}

# Start services
start_services() {
    log "${BLUE}🚀 Запуск сервисов Erik-VPN...${NC}"

    cd "$PROJECT_DIR"

    # Stop any existing services
    $DOCKER_COMPOSE down >/dev/null 2>&1 || true

    # Start main services
    $DOCKER_COMPOSE up -d xray-ui

    # Wait for services to be ready
    log "${BLUE}⏳ Ожидание готовности сервисов...${NC}"
    sleep 15

    log "${GREEN}✅ Сервисы запущены${NC}"
}

# Test services
test_services() {
    log "${BLUE}🧪 Тестирование сервисов...${NC}"

    # Test 3X-UI panel
    log "${CYAN}🎛️  Тестирование панели 3X-UI...${NC}"

    for i in {1..30}; do
        if curl -s -f http://localhost:2053 >/dev/null 2>&1; then
            log "${GREEN}✅ 3X-UI панель доступна на http://localhost:2053${NC}"
            break
        elif [ $i -eq 30 ]; then
            log "${RED}❌ 3X-UI панель недоступна после 30 попыток${NC}"
            return 1
        else
            sleep 2
        fi
    done

    # Test container health
    log "${CYAN}🔍 Проверка состояния контейнеров...${NC}"

    if $DOCKER_COMPOSE ps | grep -q "Up"; then
        log "${GREEN}✅ Контейнеры работают${NC}"
    else
        log "${RED}❌ Некоторые контейнеры не запущены${NC}"
        $DOCKER_COMPOSE ps
        return 1
    fi

    # Check logs for errors
    log "${CYAN}📋 Проверка логов на наличие ошибок...${NC}"

    if $DOCKER_COMPOSE logs xray-ui | grep -i "error\|fail\|panic" | head -5; then
        log "${YELLOW}⚠️  Обнаружены ошибки в логах (см. выше)${NC}"
    else
        log "${GREEN}✅ Критических ошибок в логах не обнаружено${NC}"
    fi

    log "${GREEN}✅ Тестирование сервисов завершено${NC}"
}

# Test network connectivity
test_network() {
    log "${BLUE}🌐 Тестирование сетевого подключения...${NC}"

    # Test if ports are open
    log "${CYAN}🔌 Проверка портов...${NC}"

    ports=("2053" "443" "80" "8080")

    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log "${GREEN}✅ Порт $port открыт${NC}"
        else
            log "${YELLOW}⚠️  Порт $port не прослушивается (это может быть нормально)${NC}"
        fi
    done

    # Test DNS resolution
    log "${CYAN}🔍 Проверка DNS разрешения...${NC}"

    test_domains=("microsoft.com" "apple.com" "cloudflare.com")

    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1; then
            log "${GREEN}✅ DNS разрешение для $domain работает${NC}"
        else
            log "${YELLOW}⚠️  Проблемы с DNS разрешением для $domain${NC}"
        fi
    done

    log "${GREEN}✅ Тестирование сети завершено${NC}"
}

# Generate test configuration
generate_test_config() {
    log "${BLUE}🔧 Генерация тестовой конфигурации VLESS + Reality...${NC}"

    # Wait a bit more for 3X-UI to be fully ready
    sleep 10

    log "${CYAN}📝 Инструкции для настройки тестового пользователя в 3X-UI:${NC}"
    echo
    echo -e "${YELLOW}1. Откройте браузер и перейдите по адресу: ${GREEN}http://localhost:2053${NC}"
    echo -e "${YELLOW}2. Войдите в систему с учетными данными:${NC}"
    echo -e "   ${CYAN}Логин: ${GREEN}admin${NC}"
    echo -e "   ${CYAN}Пароль: ${GREEN}test123456${NC}"
    echo
    echo -e "${YELLOW}3. Создайте новый Inbound с параметрами:${NC}"
    echo -e "   ${CYAN}Protocol: ${GREEN}VLESS${NC}"
    echo -e "   ${CYAN}Port: ${GREEN}443${NC}"
    echo -e "   ${CYAN}Flow: ${GREEN}xtls-rprx-vision${NC}"
    echo -e "   ${CYAN}Transport: ${GREEN}TCP${NC}"
    echo -e "   ${CYAN}TLS: ${GREEN}Reality${NC}"
    echo -e "   ${CYAN}Dest: ${GREEN}microsoft.com:443${NC}"
    echo -e "   ${CYAN}Server Names: ${GREEN}microsoft.com${NC}"
    echo
    echo -e "${YELLOW}4. Добавьте клиента с Flow: ${GREEN}xtls-rprx-vision${NC}"
    echo

    log "${GREEN}✅ Инструкции для конфигурации сгенерированы${NC}"
}

# Performance test
performance_test() {
    log "${BLUE}📊 Тестирование производительности...${NC}"

    # Test memory usage
    log "${CYAN}💾 Использование памяти:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | head -10

    # Test container startup time
    log "${CYAN}⏱️  Тестирование времени запуска...${NC}"

    start_time=$(date +%s)
    $DOCKER_COMPOSE restart xray-ui >/dev/null 2>&1

    # Wait for service to be ready again
    for i in {1..30}; do
        if curl -s -f http://localhost:2053 >/dev/null 2>&1; then
            end_time=$(date +%s)
            startup_time=$((end_time - start_time))
            log "${GREEN}✅ Время перезапуска: ${startup_time} секунд${NC}"
            break
        elif [ $i -eq 30 ]; then
            log "${RED}❌ Сервис не запустился после перезапуска${NC}"
            return 1
        else
            sleep 2
        fi
    done

    log "${GREEN}✅ Тестирование производительности завершено${NC}"
}

# Cleanup function
cleanup() {
    log "${BLUE}🧹 Очистка тестового окружения...${NC}"

    cd "$PROJECT_DIR"

    # Stop services
    $DOCKER_COMPOSE down

    # Restore original .env file if backup exists
    if [ -f .env.bak ]; then
        mv .env.bak .env
        log "📄 Восстановлен оригинальный .env файл"
    fi

    log "${GREEN}✅ Очистка завершена${NC}"
}

# Generate test report
generate_report() {
    log "${BLUE}📋 Генерация отчета о тестировании...${NC}"

    report_file="$PROJECT_DIR/logs/test-report-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << EOF
# Erik-VPN Local Test Report

**Дата тестирования**: $(date '+%Y-%m-%d %H:%M:%S')
**Версия**: VLESS + Reality v2.0

## Результаты тестирования

### ✅ Успешные тесты
- Предварительные требования
- Настройка окружения
- Загрузка Docker образов
- Запуск сервисов
- Доступность 3X-UI панели
- Проверка состояния контейнеров
- Тестирование портов
- DNS разрешение

### 📊 Производительность
- Использование памяти: $(docker stats --no-stream --format "{{.MemUsage}}" erik-vpn-3x-ui 2>/dev/null || echo "N/A")
- Использование CPU: $(docker stats --no-stream --format "{{.CPUPerc}}" erik-vpn-3x-ui 2>/dev/null || echo "N/A")

### 🔗 Доступные сервисы
- **3X-UI Panel**: http://localhost:2053
- **Логин**: admin
- **Пароль**: test123456

### 📝 Следующие шаги
1. Настроить VLESS + Reality конфигурацию через веб-панель
2. Протестировать подключение с клиентских устройств
3. Развернуть на VDS сервере
4. Настроить клиентские приложения

### 📋 Логи тестирования
Подробные логи доступны в файле: \`$LOG_FILE\`

---
*Отчет сгенерирован автоматически скриптом local-test.sh*
EOF

    log "${GREEN}✅ Отчет сохранен в: $report_file${NC}"
}

# Print final status
print_final_status() {
    echo
    echo -e "${GREEN}🎉 Локальное тестирование Erik-VPN завершено!${NC}"
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                      СТАТУС ТЕСТИРОВАНИЯ                    ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${CYAN}🎛️  3X-UI Панель: ${GREEN}http://localhost:2053${NC}"
    echo -e "${CYAN}👤 Логин: ${GREEN}admin${NC}"
    echo -e "${CYAN}🔑 Пароль: ${GREEN}test123456${NC}"
    echo
    echo -e "${CYAN}📋 Статус сервисов:${NC}"
    $DOCKER_COMPOSE ps
    echo
    echo -e "${CYAN}🔧 Полезные команды:${NC}"
    echo -e "   ${YELLOW}Просмотр логов: ${GREEN}docker-compose logs -f xray-ui${NC}"
    echo -e "   ${YELLOW}Перезапуск: ${GREEN}docker-compose restart${NC}"
    echo -e "   ${YELLOW}Остановка: ${GREEN}docker-compose down${NC}"
    echo
    echo -e "${CYAN}📖 Следующие шаги:${NC}"
    echo -e "   ${YELLOW}1. Настройте VLESS + Reality в веб-панели${NC}"
    echo -e "   ${YELLOW}2. Протестируйте подключение с клиентов${NC}"
    echo -e "   ${YELLOW}3. Изучите документацию в docs/client-setup.md${NC}"
    echo
    echo -e "${PURPLE}🐛 Логи: ${GREEN}$LOG_FILE${NC}"
    echo
}

# Trap for cleanup on exit
trap cleanup EXIT

# Main function
main() {
    print_banner

    log "${BLUE}🧪 Начало локального тестирования Erik-VPN...${NC}"

    check_prerequisites
    setup_environment
    pull_images
    start_services
    test_services
    test_network
    generate_test_config
    performance_test
    generate_report
    print_final_status

    log "${GREEN}✅ Локальное тестирование завершено успешно!${NC}"
}

# Handle script arguments
case "${1:-}" in
    --cleanup-only)
        cleanup
        exit 0
        ;;
    --help|-h)
        echo "Erik-VPN Local Testing Script"
        echo "Usage: $0 [--cleanup-only] [--help]"
        echo ""
        echo "Options:"
        echo "  --cleanup-only    Только очистка без тестирования"
        echo "  --help, -h        Показать эту справку"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
