#!/bin/bash

# Простой запуск Spring Boot приложений
set -e

echo "🚀 Starting Java Applications Manager..."
echo "📁 Apps directory: /apps"

# Устанавливаем права на выполнение
chmod +x /usr/local/bin/java-runner.sh

# Проверяем наличие Java
java -version

# Функция для установки зависимостей
install_dependencies() {
    echo "📦 Installing dependencies..."
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y curl python3 > /dev/null 2>&1
    echo "✅ Dependencies installed"
}

# Функция запуска приложения
start_app() {
    local app_dir="$1"
    local app_name=$(basename "$app_dir")
    local port=${2:-8080}

    echo "🎯 Processing application: $app_name"

    # Ищем JAR файл
    local jar_file=""
    if [ -f "$app_dir/target/"*.jar ]; then
        jar_file=$(find "$app_dir/target/" -name "*.jar" | head -n 1)
    elif [ -f "$app_dir/build/libs/"*.jar ]; then
        jar_file=$(find "$app_dir/build/libs/" -name "*.jar" | head -n 1)
    elif [ -f "$app_dir/"*.jar ]; then
        jar_file=$(find "$app_dir/" -maxdepth 1 -name "*.jar" | head -n 1)
    fi

    if [ -z "$jar_file" ]; then
        echo "⚠️  No JAR file found in $app_dir"
        echo "   Checked: target/, build/libs/, and root directory"
        return 1
    fi

    echo "📦 Found JAR: $jar_file"

    # Запускаем приложение в фоне
    cd "$app_dir"
    nohup java $JAVA_OPTS \
        -Dserver.port=$port \
        -Dspring.application.name="$app_name" \
        -Dspring.datasource.url="jdbc:mariadb://${DB_HOST}:${DB_PORT}/${app_name}_db" \
        -Dspring.datasource.username="$DB_USER" \
        -Dspring.datasource.password="$DB_PASSWORD" \
        -Dspring.datasource.driver-class-name="org.mariadb.jdbc.Driver" \
        -Dspring.jpa.hibernate.ddl-auto="update" \
        -Dspring.jpa.show-sql="false" \
        -Dlogging.level.org.springframework.web="INFO" \
        -jar "$jar_file" > "/var/log/${app_name}.log" 2>&1 &

    local pid=$!
    echo "$pid" > "/tmp/${app_name}.pid"
    echo "✅ $app_name started with PID: $pid on port $port"

    # Ждем запуска приложения
    echo "⏳ Waiting for $app_name to start..."
    sleep 5

    # Проверяем, что процесс жив
    if kill -0 "$pid" 2>/dev/null; then
        echo "🎉 $app_name is running successfully!"
    else
        echo "❌ $app_name failed to start. Check logs: /var/log/${app_name}.log"
        return 1
    fi
}

# Простой HTTP роутер
start_router() {
    echo "🌐 Starting HTTP router on port 8080..."

    cat > /tmp/app_router.py << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import subprocess
import time
from urllib.parse import urlparse
import threading

class JavaAppRouter(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.handle_request()

    def do_POST(self):
        self.handle_request()

    def handle_request(self):
        try:
            # Получаем имя приложения из заголовка X-App-Name
            app_name = self.headers.get('X-App-Name', '').strip()

            if not app_name:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Missing X-App-Name header')
                return

            # Проверяем, существует ли приложение
            app_dir = f"/apps/{app_name}"
            if not os.path.exists(app_dir):
                self.send_response(404)
                self.end_headers()
                self.wfile.write(f"Application {app_name} not found".encode())
                return

            # Простой ответ (в реальности здесь будет проксирование)
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            response = f"""
            <html>
            <head><title>Java App: {app_name}</title></head>
            <body>
                <h1>Application: {app_name}</h1>
                <p>Status: Running</p>
                <p>Directory: {app_dir}</p>
                <p>Time: {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
            </body>
            </html>
            """
            self.wfile.write(response.encode())

        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f"Error: {str(e)}".encode())
            print(f"Router error: {e}")

if __name__ == "__main__":
    PORT = 8080
    with socketserver.TCPServer(("", PORT), JavaAppRouter) as httpd:
        print(f"Router serving on port {PORT}")
        httpd.serve_forever()
PYEOF

    python3 /tmp/app_router.py &
    echo "✅ Router started"
}

# Основная логика
main() {
    install_dependencies

    echo "🔍 Scanning for Java applications..."

    # Подсчитываем приложения
    app_count=0
    for app_dir in /apps/*/; do
        if [ -d "$app_dir" ]; then
            ((app_count++))
        fi
    done

    if [ $app_count -eq 0 ]; then
        echo "⚠️  No applications found in /apps/"
        echo "📁 Expected structure: /apps/app-name/target/app.jar"
        echo "🔄 Starting router only..."
        start_router
        wait
        return 0
    fi

    echo "📊 Found $app_count applications"

    # Запускаем приложения
    current_port=8080
    for app_dir in /apps/*/; do
        if [ -d "$app_dir" ]; then
            start_app "$app_dir" $current_port &
            sleep 2  # Задержка между запусками
            ((current_port++))
        fi
    done

    # Запускаем роутер
    start_router

    echo "🎉 All applications processed!"
    echo "📋 Monitoring applications..."

    # Мониторинг
    while true; do
        sleep 30
        echo "💓 Heartbeat - $(date)"

        # Проверяем живые процессы
        for pid_file in /tmp/*.pid; do
            if [ -f "$pid_file" ]; then
                pid=$(cat "$pid_file" 2>/dev/null || echo "")
                app_name=$(basename "$pid_file" .pid)

                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    echo "✅ $app_name (PID: $pid) - OK"
                else
                    echo "💀 $app_name - DEAD, removing PID file"
                    rm -f "$pid_file"
                fi
            fi
        done
    done
}

# Обработка сигналов
cleanup() {
    echo "🛑 Shutting down applications..."
    for pid_file in /tmp/*.pid; do
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file" 2>/dev/null || echo "")
            if [ -n "$pid" ]; then
                echo "Stopping PID: $pid"
                kill "$pid" 2>/dev/null || true
            fi
            rm -f "$pid_file"
        fi
    done
    exit 0
}

trap cleanup SIGTERM SIGINT

# Запуск
main