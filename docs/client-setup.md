# 📱 Настройка клиентов Erik-VPN

Подробное руководство по настройке WireGuard клиентов на всех устройствах и операционных системах.

## 📋 Общие принципы

### Как работает WireGuard:
1. **Сервер** имеет публичный IP и порт (обычно 51820)
2. **Клиенты** подключаются к серверу используя конфигурационные файлы
3. **Туннель** создается между клиентом и сервером
4. **Весь трафик** (или выборочный) проходит через этот туннель

### Типы конфигураций:
- **Полный туннель** (0.0.0.0/0) - весь трафик через VPN
- **Разделенный туннель** - только определенные сети через VPN
- **Только локальная сеть** - доступ только к локальным ресурсам сервера

## 🌐 Создание клиентов через веб-интерфейс

### Шаг 1: Доступ к админ-панели
1. Откройте браузер
2. Перейдите по адресу: `http://YOUR-SERVER-IP:51821`
3. Введите пароль администратора

### Шаг 2: Создание нового клиента
1. Нажмите кнопку **"+ Add Client"**
2. Введите имя клиента (например: "iPhone-John", "Laptop-Home")
3. Нажмите **"Create"**

### Шаг 3: Получение конфигурации
- **QR-код** - для мобильных устройств
- **Download** - файл .conf для компьютеров
- **Config** - текстовая конфигурация для копирования

## 📱 Мобильные устройства

### Android

#### Установка приложения:
1. Откройте Google Play Store
2. Найдите и установите **"WireGuard"** (официальное приложение)
3. Запустите приложение

#### Добавление конфигурации:

**Метод 1: QR-код (Рекомендуется)**
1. В приложении нажмите **"+"**
2. Выберите **"Scan from QR code"**
3. Отсканируйте QR-код из веб-интерфейса

**Метод 2: Файл конфигурации**
1. Скачайте .conf файл на устройство
2. В приложении нажмите **"+"**
3. Выберите **"Import from file or archive"**
4. Выберите скачанный файл

**Метод 3: Ручной ввод**
1. В приложении нажмите **"+"**
2. Выберите **"Create from scratch"**
3. Введите данные из текстовой конфигурации

#### Подключение:
1. Найдите созданный профиль в списке
2. Нажмите переключатель справа от имени профиля
3. Подтвердите создание VPN подключения

### iPhone/iPad (iOS)

#### Установка приложения:
1. Откройте App Store
2. Найдите и установите **"WireGuard"**
3. Запустите приложение

#### Добавление конфигурации:

**Метод 1: QR-код (Рекомендуется)**
1. Нажмите **"+"** в правом верхнем углу
2. Выберите **"Add a tunnel"**
3. Выберите **"Scan from QR Code"**
4. Отсканируйте QR-код

**Метод 2: Файл конфигурации**
1. Отправьте .conf файл на устройство (email, AirDrop, облако)
2. Откройте файл
3. Выберите **"Open in WireGuard"**

#### Подключение:
1. Найдите профиль в списке туннелей
2. Переведите переключатель в положение "ON"
3. Разрешите создание VPN конфигурации

### Настройки для мобильных устройств:

#### Экономия батареи:
- Отключите **"On-demand activation"** если не нужно
- Используйте **"Kill switch"** только при необходимости

#### Разделенный туннель:
```
# В поле AllowedIPs укажите только нужные сети
AllowedIPs = 192.168.1.0/24, 10.0.0.0/8
# Вместо AllowedIPs = 0.0.0.0/0
```

## 💻 Компьютеры

### Windows

#### Установка:
1. Скачайте WireGuard с официального сайта: https://www.wireguard.com/install/
2. Запустите установщик от имени администратора
3. Следуйте инструкциям установки

#### Добавление конфигурации:
1. Откройте WireGuard приложение
2. Нажмите **"Import tunnel(s) from file"**
3. Выберите скачанный .conf файл
4. Или нажмите **"Add empty tunnel"** для ручного ввода

#### Подключение:
1. Выберите туннель в списке
2. Нажмите **"Activate"**

### macOS

#### Установка:
1. Откройте Mac App Store
2. Найдите и установите **"WireGuard"**
3. Или скачайте с официального сайта

#### Настройка:
1. Откройте WireGuard
2. Нажмите **"+"** для добавления туннеля
3. Выберите **"Import tunnel(s) from file"**
4. Выберите .conf файл

### Linux

#### Ubuntu/Debian:
```bash
# Установка
sudo apt update
sudo apt install wireguard

# Копирование конфигурации
sudo cp client.conf /etc/wireguard/wg0.conf

# Запуск
sudo wg-quick up wg0

# Автозапуск
sudo systemctl enable wg-quick@wg0

# Остановка
sudo wg-quick down wg0
```

#### CentOS/RHEL:
```bash
# Установка
sudo yum install epel-release
sudo yum install wireguard-tools

# Или для новых версий
sudo dnf install wireguard-tools

# Дальнейшие шаги аналогичны Ubuntu
```

#### Arch Linux:
```bash
# Установка
sudo pacman -S wireguard-tools

# Настройка аналогична другим дистрибутивам
```

### Настройка автозапуска в Linux:
```bash
# Включить автозапуск
sudo systemctl enable wg-quick@wg0

# Проверить статус
sudo systemctl status wg-quick@wg0

# Просмотр логов
sudo journalctl -u wg-quick@wg0
```

## 🏠 Роутеры

### OpenWrt

#### Установка пакетов:
```bash
# Подключение к роутеру
ssh root@192.168.1.1

# Обновление пакетов
opkg update

# Установка WireGuard
opkg install wireguard-tools kmod-wireguard

# Для веб-интерфейса
opkg install luci-proto-wireguard
```

#### Настройка через веб-интерфейс:
1. Откройте LuCI веб-интерфейс
2. Перейдите в **Network > Interfaces**
3. Нажмите **"Add new interface"**
4. Выберите протокол **"WireGuard VPN"**
5. Введите конфигурацию

#### Настройка через командную строку:
```bash
# Создание конфигурации
cat > /etc/config/network << EOF
config interface 'wg0'
    option proto 'wireguard'
    option private_key 'YOUR_PRIVATE_KEY'
    list addresses '10.8.0.2/24'

config wireguard_wg0
    option public_key 'SERVER_PUBLIC_KEY'
    option endpoint_host 'YOUR_SERVER_IP'
    option endpoint_port '51820'
    option route_allowed_ips '1'
    list allowed_ips '0.0.0.0/0'
EOF

# Применение настроек
/etc/init.d/network reload
```

### DD-WRT

DD-WRT имеет ограниченную поддержку WireGuard. Рекомендуется обновить прошивку до OpenWrt.

### Mikrotik RouterOS

```bash
# Создание интерфейса WireGuard
/interface wireguard add listen-port=51820 name=wg0

# Генерация ключей
/interface wireguard print

# Настройка пира (сервера)
/interface wireguard peers add allowed-address=0.0.0.0/0 endpoint-address=YOUR_SERVER_IP endpoint-port=51820 interface=wg0 public-key="SERVER_PUBLIC_KEY"

# Настройка IP адреса
/ip address add address=10.8.0.2/24 interface=wg0

# Настройка маршрутизации
/ip route add dst-address=0.0.0.0/0 gateway=wg0
```

## 🛠️ Примеры конфигураций

### Полный туннель (весь трафик через VPN):
```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### Разделенный туннель (только локальная сеть):
```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 192.168.1.0/24, 10.8.0.0/24
PersistentKeepalive = 25
```

### Доступ к определенным сайтам:
```ini
[Interface]
PrivateKey = CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 8.8.8.8/32, 1.1.1.1/32
PersistentKeepalive = 25
```

## 🔧 Оптимизация и настройка

### Параметры для разных сценариев:

#### Мобильный интернет (нестабильное соединение):
```ini
PersistentKeepalive = 15
```

#### Стабильное соединение:
```ini
PersistentKeepalive = 25
```

#### Экономия трафика:
```ini
# Уберите PersistentKeepalive или установите большое значение
PersistentKeepalive = 60
```

### Настройка MTU:
```ini
[Interface]
MTU = 1420  # Для большинства случаев
# MTU = 1380  # Для мобильных сетей
# MTU = 1500  # Для локальных сетей
```

## 🚨 Устранение неполадок

### Проблема: Не удается подключиться

**Проверьте:**
1. Правильность IP-адреса сервера
2. Открыт ли порт 51820/udp на сервере
3. Корректность ключей в конфигурации

### Проблема: Медленное соединение

**Решения:**
1. Измените MTU на 1420 или 1380
2. Проверьте пропускную способность сервера
3. Попробуйте другой DNS сервер

### Проблема: Некоторые сайты не работают

**Решения:**
1. Используйте разделенный туннель
2. Измените DNS на 8.8.8.8, 1.1.1.1
3. Проверьте настройки AllowedIPs

### Команды для диагностики:

#### На клиенте:
```bash
# Проверка статуса соединения
sudo wg show

# Проверка маршрутов
ip route show

# Тест подключения
ping 10.8.0.1  # IP сервера в VPN сети
```

#### На сервере:
```bash
# Просмотр подключенных клиентов
docker exec erik-vpn wg show

# Просмотр логов
docker-compose logs -f
```

## 📊 Мониторинг подключений

### Проверка статуса через веб-интерфейс:
1. Откройте веб-интерфейс `http://YOUR-SERVER-IP:51821`
2. В списке клиентов видно:
   - Статус подключения (зеленый/красный)
   - Время последнего подключения
   - Переданные данные

### Настройка уведомлений:
- В веб-интерфейсе можно настроить email уведомления
- Логи автоматически сохраняются в папку `logs/`

## 🎯 Следующие шаги

После настройки клиентов рекомендуется:
- [Настроить безопасность](security.md)
- [Изучить устранение неполадок](troubleshooting.md)
- [Настроить мониторинг](monitoring.md)

## 📚 Полезные ссылки

- [Официальная документация WireGuard](https://www.wireguard.com/)
- [WireGuard для Android](https://play.google.com/store/apps/details?id=com.wireguard.android)
- [WireGuard для iOS](https://apps.apple.com/app/wireguard/id1441195209)
- [WireGuard для Windows](https://www.wireguard.com/install/)
