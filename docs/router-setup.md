# 🏠 Установка Erik-VPN на роутер

Подробное руководство по развертыванию WireGuard VPN сервера на домашних роутерах. Это позволит создать VPN сервер прямо у вас дома.

## 🎯 Преимущества установки на роутер

- **Всегда доступен**: Роутер работает 24/7
- **Экономично**: Не нужно платить за VPS
- **Локальный доступ**: Подключение к домашней сети из любой точки мира
- **Высокая скорость**: Прямое подключение к домашнему интернету
- **Приватность**: Полный контроль над данными

## 📋 Требования к роутеру

### Минимальные характеристики:
- **CPU**: ARM или MIPS с частотой 500MHz+
- **RAM**: 64MB+ (рекомендуется 128MB+)
- **Флеш**: 16MB+ (рекомендуется 32MB+)
- **Поддержка**: OpenWrt, DD-WRT или нативная поддержка Docker

### Поддерживаемые модели роутеров:

#### ✅ Отлично поддерживаются:
- **Raspberry Pi** (с OpenWrt или Raspberry Pi OS)
- **GL.iNet**: GL-AX1800, GL-AXT1800, GL-B1300, GL-MT1300
- **Linksys**: WRT1900ACS, WRT1900AC, WRT1200AC
- **Netgear**: R7800, R7500v2, R6400v2
- **TP-Link**: Archer C7, Archer A7, AC1750
- **ASUS**: RT-AC86U, RT-AX88U (с поддержкой Entware)

#### ⚠️ Требуют модификации:
- **Mikrotik**: RouterBoard серии (поддержка WireGuard с v7.0+)
- **Ubiquiti**: EdgeRouter, UniFi Dream Machine
- **D-Link**: DIR-878, DIR-882

## 🚀 Метод 1: OpenWrt (Рекомендуется)

### Проверка совместимости
Проверьте, поддерживает ли ваш роутер OpenWrt: https://openwrt.org/toh/start

### Установка OpenWrt

⚠️ **Внимание**: Прошивка роутера может привести к потере гарантии и "кирпичу". Делайте на свой страх и риск!

#### Шаг 1: Подготовка
```bash
# Узнайте точную модель роутера
cat /proc/cpuinfo
cat /proc/version

# Скачайте прошивку с официального сайта OpenWrt
# Выберите вашу модель: https://openwrt.org/toh/start
```

#### Шаг 2: Прошивка (пример для TP-Link Archer C7)
1. Скачайте файл прошивки (.bin или .trx)
2. Зайдите в веб-интерфейс роутера (обычно 192.168.1.1)
3. Найдите раздел "Firmware Upgrade" или "System Tools"
4. Загрузите файл прошивки
5. Дождитесь завершения (НЕ ВЫКЛЮЧАЙТЕ роутер!)

#### Шаг 3: Первоначальная настройка OpenWrt
```bash
# Подключитесь к роутеру через SSH
ssh root@192.168.1.1

# Установите пароль
passwd

# Обновите пакеты
opkg update
```

### Установка WireGuard на OpenWrt

#### Способ 1: Через веб-интерфейс (LuCI)

```bash
# Установка веб-интерфейса
opkg install luci
/etc/init.d/uhttpd start
/etc/init.d/uhttpd enable

# Установка WireGuard с веб-интерфейсом
opkg install wireguard-tools kmod-wireguard
opkg install luci-proto-wireguard luci-app-wireguard
```

Затем:
1. Откройте http://192.168.1.1 в браузере
2. Войдите с паролем root
3. Перейдите в **Network → Interfaces**
4. Добавьте новый интерфейс типа **WireGuard VPN**

#### Способ 2: Через командную строку

```bash
# Установка WireGuard
opkg install wireguard-tools kmod-wireguard

# Генерация ключей сервера
wg genkey | tee /etc/wireguard/server_private_key | wg pubkey > /etc/wireguard/server_public_key

# Создание конфигурации сервера
cat > /etc/config/network << 'EOF'
config interface 'wg0'
    option proto 'wireguard'
    option private_key_file '/etc/wireguard/server_private_key'
    option listen_port '51820'
    list addresses '10.8.0.1/24'

config wireguard_wg0
    option description 'Client 1'
    option public_key 'CLIENT_PUBLIC_KEY_HERE'
    list allowed_ips '10.8.0.2/32'
EOF

# Настройка файрвола
cat > /etc/config/firewall << 'EOF'
config zone
    option name 'wg'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'
    option masq '1'
    list network 'wg0'

config forwarding
    option src 'wg'
    option dest 'wan'

config rule
    option name 'Allow-WireGuard'
    option src 'wan'
    option dest_port '51820'
    option proto 'udp'
    option target 'ACCEPT'
EOF

# Применение настроек
/etc/init.d/network reload
/etc/init.d/firewall reload
```

## 🔧 Метод 2: Raspberry Pi

Raspberry Pi - отличный выбор для домашнего VPN сервера.

### Подготовка Raspberry Pi

#### Установка Raspberry Pi OS Lite:
1. Скачайте Raspberry Pi Imager
2. Выберите "Raspberry Pi OS Lite (64-bit)"
3. Настройте SSH и WiFi при записи на SD карту

#### Первоначальная настройка:
```bash
# Подключение по SSH
ssh pi@raspberrypi.local

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install curl git
```

### Установка с помощью нашего скрипта:

```bash
# Клонирование репозитория
git clone https://github.com/your-username/Erik-VPN.git
cd Erik-VPN

# Запуск установки
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Ручная установка на Raspberry Pi:

```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi

# Установка Docker Compose
sudo apt install docker-compose

# Включение IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Настройка конфигурации
cp env.example .env
nano .env  # Настройте WG_HOST и ADMIN_PASSWORD

# Запуск
docker-compose up -d
```

## ⚙️ Метод 3: ASUS Routers (Entware)

Для роутеров ASUS с прошивкой Merlin или поддержкой Entware.

### Подготовка:
```bash
# Подключение к роутеру
ssh admin@192.168.1.1

# Установка Entware (если не установлен)
# Следуйте инструкциям: https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware
```

### Установка WireGuard:
```bash
# Обновление пакетов Entware
opkg update

# Установка WireGuard
opkg install wireguard-tools

# Создание конфигурации
mkdir -p /opt/etc/wireguard
wg genkey | tee /opt/etc/wireguard/privatekey | wg pubkey > /opt/etc/wireguard/publickey

# Создание файла конфигурации
cat > /opt/etc/wireguard/wg0.conf << 'EOF'
[Interface]
PrivateKey = PASTE_SERVER_PRIVATE_KEY_HERE
Address = 10.8.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = CLIENT_PUBLIC_KEY_HERE
AllowedIPs = 10.8.0.2/32
EOF

# Запуск
wg-quick up wg0

# Автозапуск
echo "wg-quick up wg0" >> /jffs/scripts/wan-start
chmod +x /jffs/scripts/wan-start
```

## 🌐 Метод 4: Mikrotik RouterOS

Для роутеров Mikrotik с RouterOS 7.0+

### Через веб-интерфейс (WinBox):
1. Откройте WinBox или веб-интерфейс
2. Перейдите в **WireGuard**
3. Создайте новый интерфейс
4. Настройте пиры (clients)

### Через командную строку:
```bash
# Создание интерфейса WireGuard
/interface/wireguard/add name=wg0 listen-port=51820

# Генерация ключей (будут показаны автоматически)
/interface/wireguard/print

# Настройка IP адреса
/ip/address/add address=10.8.0.1/24 interface=wg0

# Добавление клиента
/interface/wireguard/peers/add interface=wg0 public-key="CLIENT_PUBLIC_KEY" allowed-address=10.8.0.2/32

# Настройка NAT
/ip/firewall/nat/add chain=srcnat action=masquerade out-interface=ether1 src-address=10.8.0.0/24

# Разрешение подключений
/ip/firewall/filter/add chain=input action=accept protocol=udp dst-port=51820
```

## 🔒 Настройка безопасности

### Файрвол и порты:
```bash
# Для OpenWrt
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-WireGuard'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='51820'
uci set firewall.@rule[-1].proto='udp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall reload
```

### Настройка DDNS (динамический DNS):
Если у вас динамический IP от провайдера:

```bash
# Для OpenWrt
opkg install ddns-scripts luci-app-ddns

# Настройте в веб-интерфейсе:
# Services → Dynamic DNS
```

Популярные DDNS сервисы:
- **No-IP** (бесплатный)
- **DuckDNS** (бесплатный)
- **Dynu** (бесплатный)

## 📶 Оптимизация производительности

### Настройка QoS:
```bash
# Ограничение скорости VPN (необязательно)
tc qdisc add dev wg0 root tbf rate 50mbit burst 32kbit latency 400ms
```

### Оптимизация для слабых роутеров:
```bash
# Уменьшение MTU для экономии ресурсов
echo 'MTU = 1280' >> /etc/wireguard/wg0.conf

# Увеличение keepalive для экономии трафика
echo 'PersistentKeepalive = 60' >> /etc/wireguard/wg0.conf
```

## 🔄 Обновление и обслуживание

### Автоматическое обновление OpenWrt:
```bash
# Создание скрипта обновления
cat > /root/update_packages.sh << 'EOF'
#!/bin/sh
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade
EOF

chmod +x /root/update_packages.sh

# Добавление в crontab (еженедельно)
echo "0 3 * * 0 /root/update_packages.sh" >> /etc/crontabs/root
/etc/init.d/cron restart
```

### Резервное копирование конфигурации:
```bash
# Создание бэкапа настроек OpenWrt
sysupgrade -b /tmp/backup-$(date +%Y%m%d).tar.gz

# Сохранение WireGuard ключей
tar -czf /tmp/wg-backup-$(date +%Y%m%d).tar.gz /etc/wireguard/
```

## 🚨 Устранение неполадок

### Проблема: Низкая производительность

**Решения:**
```bash
# Проверка загрузки CPU
top

# Проверка использования памяти
free -m

# Оптимизация настроек ядра
echo 'net.core.default_qdisc = fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
sysctl -p
```

### Проблема: Роутер зависает

**Решения:**
1. Уменьшите количество одновременных подключений
2. Увеличьте `PersistentKeepalive` до 60 секунд
3. Используйте более простой алгоритм шифрования

### Проблема: Не работает после перезагрузки

```bash
# Проверка автозапуска
/etc/init.d/wireguard enable

# Добавление в автозагрузку (OpenWrt)
echo "wg-quick up wg0" >> /etc/rc.local
```

## 📊 Мониторинг

### Простой мониторинг через SSH:
```bash
# Статус WireGuard
wg show

# Использование ресурсов
htop

# Сетевая активность
iftop -i wg0
```

### Веб-мониторинг (для более мощных роутеров):
```bash
# Установка простого веб-мониторинга
opkg install luci-app-statistics collectd-mod-interface
```

## 🔗 Настройка доступа из интернета

### Проброс портов на основном роутере:
Если VPN роутер находится за NAT основного роутера:

1. Зайдите в настройки основного роутера
2. Найдите раздел "Port Forwarding" или "Virtual Servers"
3. Добавьте правило:
   - **Внешний порт**: 51820 (UDP)
   - **Внутренний IP**: IP адрес VPN роутера
   - **Внутренний порт**: 51820 (UDP)

### Статический IP адрес:
```bash
# Назначение статического IP для VPN роутера
# В настройках основного роутера в разделе DHCP Reservation
```

## 🎯 Рекомендации по выбору роутера

### Бюджетные варианты ($50-100):
- **GL.iNet GL-AXT1800** - отлично для начинающих
- **TP-Link Archer A7** - хорошая производительность
- **Raspberry Pi 4** + USB-Ethernet адаптер

### Продвинутые варианты ($100-200):
- **Netgear R7800** - высокая производительность
- **Linksys WRT1900ACS** - отличная поддержка OpenWrt
- **ASUS RT-AC86U** - мощный процессор

### Профессиональные варианты ($200+):
- **Mikrotik RB4011** - максимальная гибкость
- **Ubiquiti Dream Machine** - корпоративное качество
- **PC Engines APU2** - промышленное решение

## 📚 Полезные ссылки

- [OpenWrt Table of Hardware](https://openwrt.org/toh/start)
- [WireGuard на OpenWrt](https://openwrt.org/docs/guide-user/services/vpn/wireguard/basics)
- [GL.iNet документация](https://docs.gl-inet.com/)
- [ASUS Merlin firmware](https://www.asuswrt-merlin.net/)

## 🎯 Следующие шаги

После установки на роутер:
- [Настройте клиенты](client-setup.md)
- [Изучите вопросы безопасности](security.md)
- [Настройте мониторинг](monitoring.md)
