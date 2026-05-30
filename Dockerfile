FROM php:8.3-fpm

RUN apt update && apt install -y \
    nginx \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    zip \
    xml \
    bcmath \
    intl \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

RUN rm -rf /var/www/html/* /var/www/html/.* 2>/dev/null || true \
    && git clone https://github.com/mathesh171/tictactoe.git /tmp/tictactoe \
    && cp -a /tmp/tictactoe/. /var/www/html \
    && rm -rf /tmp/tictactoe

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN mkdir -p storage/logs bootstrap/cache \
    && touch storage/logs/laravel.log \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

RUN cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/html/public;
    index index.php index.html;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

RUN cat > /start.sh <<'EOF'
#!/bin/bash
set -e

cat > /var/www/html/.env <<ENVEOF
APP_NAME=${APP_NAME}
APP_ENV=${APP_ENV}
APP_KEY=
APP_DEBUG=${APP_DEBUG}
APP_URL=${APP_URL}
ASSET_URL=${ASSET_URL}

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=${DB_CONNECTION}
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
ENVEOF

php artisan optimize:clear || true
php artisan key:generate --force || true
php artisan migrate --force || true

php artisan config:cache || true
php artisan route:cache || true
php artisan view:cache || true

php-fpm -D
nginx -g "daemon off;"
EOF

RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
