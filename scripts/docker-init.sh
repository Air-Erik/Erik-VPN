#!/bin/sh
# Инициализация 3X-UI с настройками из переменных окружения

INIT_MARKER="/etc/x-ui/.initialized"

# Функция для применения настроек
apply_settings() {
    echo "[init] Applying settings from environment variables..."

    # Применяем username и password если заданы
    if [ -n "$XUI_USERNAME" ] && [ -n "$XUI_PASSWORD" ]; then
        echo "[init] Setting username: $XUI_USERNAME"
        /app/x-ui setting -username "$XUI_USERNAME" -password "$XUI_PASSWORD"
    fi

    # Применяем base path если задан
    if [ -n "$XUI_BASE_PATH" ]; then
        echo "[init] Setting webBasePath: $XUI_BASE_PATH"
        /app/x-ui setting -webBasePath "$XUI_BASE_PATH"
    fi

    # Создаём маркер инициализации
    touch "$INIT_MARKER"
    echo "[init] Settings applied successfully"
}

# Запускаем fail2ban если включен
if [ "$XUI_ENABLE_FAIL2BAN" = "true" ]; then
    fail2ban-client -x start
fi

# Применяем настройки только при первом запуске (если маркера нет)
if [ ! -f "$INIT_MARKER" ]; then
    # Даём x-ui создать базу данных
    /app/x-ui &
    XUI_PID=$!

    # Ждём пока панель запустится
    echo "[init] Waiting for x-ui to start..."
    sleep 5

    # Останавливаем x-ui
    kill $XUI_PID 2>/dev/null
    wait $XUI_PID 2>/dev/null

    # Применяем настройки
    apply_settings
fi

# Запускаем x-ui
echo "[init] Starting x-ui..."
exec /app/x-ui
