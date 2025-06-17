# Установка Erik-VPN с VLESS + Reality

Подробное руководство по установке и настройке Erik-VPN с протоколом VLESS + Reality и панелью управления 3X-UI.

## 🚀 Быстрая установка

### Автоматическая установка (рекомендуется)

```bash
# Клонируйте репозиторий
git clone https://github.com/your-username/Erik-VPN.git
cd Erik-VPN

# Запустите скрипт установки
./scripts/deploy.sh
```

Скрипт автоматически:
- Определит вашу операционную систему
- Установит Docker и Docker Compose
- Создаст необходимые каталоги
- Сгенерирует безопасные пароли
- Настроит брандмауэр
- Запустит сервисы

### Ручная установка

Если вы предпочитаете ручную настройку или автоматический скрипт не работает:

#### 1. Установка Docker

**Ubuntu/Debian:**
```bash
# Удалите старые версии
sudo apt-get remove docker docker-engine docker.io containerd runc

# Обновите пакеты
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release

# Добавьте GPG ключ Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавьте репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установите Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER
```

**CentOS/RHEL/Fedora:**
```bash
# Удалите старые версии
sudo yum remove docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Установите необходимые пакеты
sudo yum install -y yum-utils

# Добавьте репозиторий Docker
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

# Установите Docker
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запустите Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

#### 2. Настройка проекта

```bash
# Создайте структуру каталогов
mkdir -p data/3x-ui certs logs/{xray,nginx} nginx/conf.d monitoring fail2ban

# Скопируйте файл конфигурации
cp env.example .env

# Отредактируйте конфигурацию
nano .env
```

#### 3. Запуск сервисов

```bash
# Запустите Erik-VPN
docker-compose up -d

# Проверьте статус
docker-compose ps

# Просмотрите логи
docker-compose logs -f xray-ui
```

## 🛠️ Настройка 3X-UI панели

### Первоначальная настройка

1. **Доступ к панели**: Откройте `http://your-server-ip:2053` в браузере
2. **Вход в систему**:
   - Логин: `admin`
   - Пароль: указан в файле `.env` (переменная `ADMIN_PASSWORD`)

### Создание пользователя VLESS + Reality

1. **Перейдите в раздел "Inbounds"**
2. **Нажмите "+" для добавления нового inbound**
3. **Заполните параметры**:
   ```
   Remark: VLESS-Reality-User1
   Protocol: VLESS
   Listen IP: 0.0.0.0
   Port: 443
   ```

4. **Настройте XTLS-Reality**:
   ```
   Flow: xtls-rprx-vision
   uTLS: chrome
   Dest: microsoft.com:443
   Server Names: microsoft.com
   ```

5. **Добавьте клиента**:
   ```
   ID: (генерируется автоматически)
   Flow: xtls-rprx-vision
   Email: user1@example.com
   ```

6. **Сохраните конфигурацию**

### Популярные сайты для маскировки Reality

| Сайт | Причина выбора |
|------|----------------|
| `microsoft.com` | Высокий трафик, стабильные сертификаты |
| `apple.com` | Популярный, надежный SSL |
| `cloudflare.com` | CDN провайдер, много подключений |
| `github.com` | Разработчики, техническая аудитория |
| `aws.amazon.com` | Облачные сервисы, B2B трафик |

## 🔧 Дополнительные настройки

### Оптимизация производительности

**Системные параметры:**
```bash
# Добавьте в /etc/sysctl.conf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr

# Примените изменения
sudo sysctl -p
```

**Docker оптимизации:**
```yaml
# В docker-compose.yml
sysctls:
  - net.core.rmem_max=16777216
  - net.core.wmem_max=16777216
  - net.ipv4.tcp_congestion_control=bbr
```

### SSL сертификаты

**Самоподписанные сертификаты:**
```bash
# Создайте самоподписанный сертификат
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com"
```

**Let's Encrypt (для продакшена):**
```bash
# Установите certbot
sudo apt-get install certbot

# Получите сертификат
sudo certbot certonly --standalone -d yourdomain.com

# Скопируйте сертификаты
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem certs/cert.pem
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem certs/key.pem
sudo chown $USER:$USER certs/*.pem
```

### Настройка брандмауэра

**UFW (Ubuntu/Debian):**
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 2053/tcp comment "3X-UI Panel"
sudo ufw allow 443/tcp comment "VLESS Reality"
sudo ufw allow 80/tcp comment "VMess"
sudo ufw allow 8080/tcp comment "VLESS Alt"
```

**Firewalld (CentOS/RHEL):**
```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=2053/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## 📊 Мониторинг (опционально)

### Включение мониторинга

```bash
# Запустите с профилем мониторинга
docker-compose --profile monitoring up -d

# Доступ к сервисам
# Prometheus: http://your-server:9090
# Grafana: http://your-server:3000
```

### Настройка Grafana

1. **Войдите в Grafana**:
   - URL: `http://your-server:3000`
   - Логин: `admin`
   - Пароль: указан в `.env` (переменная `GRAFANA_PASSWORD`)

2. **Добавьте источник данных Prometheus**:
   - URL: `http://prometheus:9090`
   - Сохраните и протестируйте

3. **Импортируйте готовые дашборды**:
   - Node Exporter Full: ID `1860`
   - Docker Container Metrics: ID `193`

## 🔒 Безопасность

### Fail2Ban (опционально)

```bash
# Включите Fail2Ban
docker-compose --profile security up -d fail2ban

# Проверьте статус
docker-compose exec fail2ban fail2ban-client status
```

### Регулярные обновления

```bash
# Создайте cron job для автоматических обновлений
echo "0 4 * * * cd /path/to/Erik-VPN && docker-compose pull && docker-compose up -d" | crontab -
```

## 🚨 Устранение неполадок

### Проверка статуса сервисов

```bash
# Статус контейнеров
docker-compose ps

# Логи всех сервисов
docker-compose logs

# Логи конкретного сервиса
docker-compose logs xray-ui

# Использование ресурсов
docker stats
```

### Общие проблемы

**Проблема**: Панель 3X-UI недоступна
```bash
# Проверьте запущен ли контейнер
docker-compose ps xray-ui

# Проверьте порты
netstat -tulpn | grep :2053

# Проверьте логи
docker-compose logs xray-ui
```

**Проблема**: Клиент не может подключиться
```bash
# Проверьте конфигурацию Reality
docker-compose exec xray-ui xray version

# Проверьте открыты ли порты
sudo ufw status
sudo iptables -L
```

**Проблема**: Низкая скорость подключения
```bash
# Проверьте системные параметры
sysctl net.ipv4.tcp_congestion_control

# Проверьте нагрузку на систему
htop
iotop
```

## 📱 Следующие шаги

После успешной установки:

1. **[Настройка клиентов](client-setup.md)** - Подключение устройств
2. **[VDS развертывание](vds-deployment.md)** - Развертывание на VDS
3. **[Troubleshooting](troubleshooting.md)** - Решение проблем
4. **[FAQ](faq.md)** - Часто задаваемые вопросы

---

**⚠️ Важно**: Регулярно обновляйте пароли и следите за безопасностью вашего сервера!
