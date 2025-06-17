# 🛠️ Подробная инструкция по установке Erik-VPN

Этот гайд поможет вам развернуть собственный VPN сервер на базе WireGuard с веб-интерфейсом для управления пользователями.

## 📋 Требования

### Минимальные системные требования:
- **CPU**: 1 ядро (x86_64 или ARM64)
- **RAM**: 512MB (рекомендуется 1GB+)
- **Диск**: 2GB свободного места
- **Сеть**: Статический публичный IP-адрес

### Поддерживаемые операционные системы:
- Ubuntu 20.04+ / Debian 11+
- CentOS 8+ / RHEL 8+
- Rocky Linux 8+
- Fedora 35+

## 🚀 Автоматическая установка (Рекомендуется)

### Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y  # для Ubuntu/Debian
# или
sudo yum update -y  # для CentOS/RHEL

# Клонирование репозитория
git clone https://github.com/your-username/Erik-VPN.git
cd Erik-VPN

# Делаем скрипт исполняемым
chmod +x scripts/deploy.sh
```

### Шаг 2: Запуск автоматической установки

```bash
# Запуск скрипта развертывания
./scripts/deploy.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Определит ваш внешний IP-адрес
- Настроит конфигурацию
- Создаст необходимые директории
- Настроит файрвол
- Запустит VPN сервер

### Шаг 3: Первый вход

После завершения установки:

1. Откройте браузер и перейдите по адресу: `http://YOUR-SERVER-IP:51821`
2. Введите пароль администратора (будет показан в конце установки)
3. Создайте первого пользователя через веб-интерфейс

## ⚙️ Ручная установка

Если автоматическая установка не подходит, используйте ручную настройку:

### Шаг 1: Установка Docker

#### Ubuntu/Debian:
```bash
# Удаление старых версий Docker
sudo apt-get remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

# Добавление GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Запуск и автозагрузка Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
```

#### CentOS/RHEL:
```bash
# Установка зависимостей
sudo yum install -y yum-utils

# Добавление репозитория Docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Установка Docker
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Запуск и автозагрузка Docker
sudo systemctl start docker
sudo systemctl enable docker

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
```

### Шаг 2: Установка Docker Compose (если необходимо)

```bash
# Скачивание Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Установка прав на выполнение
sudo chmod +x /usr/local/bin/docker-compose

# Проверка установки
docker-compose --version
```

### Шаг 3: Настройка конфигурации

```bash
# Копирование примера конфигурации
cp env.example .env

# Редактирование конфигурации
nano .env
```

**Обязательные параметры для изменения:**
- `WG_HOST` - ваш внешний IP или домен
- `ADMIN_PASSWORD` - пароль для веб-интерфейса

### Шаг 4: Настройка системы

```bash
# Включение IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Создание директорий
mkdir -p data logs monitoring/grafana/provisioning
```

### Шаг 5: Настройка файрвола

#### UFW (Ubuntu):
```bash
sudo ufw allow 51820/udp comment "WireGuard"
sudo ufw allow 51821/tcp comment "WireGuard Web UI"
sudo ufw reload
```

#### Firewalld (CentOS/RHEL):
```bash
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --add-port=51821/tcp
sudo firewall-cmd --reload
```

#### Iptables (универсальный):
```bash
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 51821 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Шаг 6: Запуск сервера

```bash
# Запуск контейнеров
docker-compose up -d

# Проверка статуса
docker-compose ps
docker-compose logs
```

## 🔧 Настройка провайдера VPS

### DigitalOcean

1. Создайте Droplet с Ubuntu 22.04
2. Откройте порты 51820/udp и 51821/tcp в файрволе
3. Подключитесь по SSH и следуйте инструкции

### AWS EC2

1. Запустите EC2 instance с Ubuntu 22.04
2. В Security Groups добавьте правила:
   - Custom UDP Rule, Port 51820, Source 0.0.0.0/0
   - Custom TCP Rule, Port 51821, Source 0.0.0.0/0
3. Подключитесь по SSH и следуйте инструкции

### Vultr

1. Создайте сервер с Ubuntu 22.04
2. В настройках файрвола добавьте правила для портов 51820/udp и 51821/tcp
3. Подключитесь по SSH и следуйте инструкции

### Hetzner

1. Создайте Cloud Server с Ubuntu 22.04
2. В настройках сети откройте необходимые порты
3. Подключитесь по SSH и следуйте инструкции

## 🐳 Альтернативные способы установки

### Docker без Compose

```bash
# Создание сети
docker network create erik-vpn-network

# Запуск контейнера
docker run -d \
  --name erik-vpn \
  --restart unless-stopped \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  -e WG_HOST=YOUR-SERVER-IP \
  -e PASSWORD=YOUR-ADMIN-PASSWORD \
  -p 51820:51820/udp \
  -p 51821:51821/tcp \
  -v $(pwd)/data:/etc/wireguard \
  --network erik-vpn-network \
  weejewel/wg-easy:latest
```

### Portainer (веб-интерфейс для Docker)

```bash
# Установка Portainer
docker volume create portainer_data
docker run -d -p 9000:9000 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```

## ✅ Проверка установки

### Проверка статуса контейнеров:
```bash
docker-compose ps
```

### Проверка логов:
```bash
docker-compose logs -f
```

### Проверка сетевых подключений:
```bash
sudo netstat -tulpn | grep :51820
sudo netstat -tulpn | grep :51821
```

### Тест подключения:
```bash
curl -I http://localhost:51821
```

## 🚨 Устранение неполадок

### Проблема: Контейнер не запускается

**Решение:**
```bash
# Проверка логов
docker-compose logs

# Проверка системных требований
sudo modprobe wireguard
lsmod | grep wireguard
```

### Проблема: Веб-интерфейс недоступен

**Решение:**
```bash
# Проверка файрвола
sudo ufw status
sudo iptables -L

# Проверка портов
sudo netstat -tulpn | grep :51821
```

### Проблема: Клиенты не могут подключиться

**Решение:**
```bash
# Проверка IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Проверка NAT правил
sudo iptables -t nat -L POSTROUTING
```

## 🔄 Обновление

```bash
# Остановка сервера
docker-compose down

# Обновление образов
docker-compose pull

# Запуск с новыми образами
docker-compose up -d
```

## 🗑️ Удаление

```bash
# Полное удаление
docker-compose down -v
docker system prune -a
sudo rm -rf data logs
```

## 🎯 Следующие шаги

После успешной установки переходите к:
- [Настройка сервера](server-setup.md)
- [Настройка клиентов](client-setup.md)
- [Безопасность](security.md)
