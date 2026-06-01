FROM php:8.3-fpm

RUN apt update && apt install -y \
    nginx git unzip curl \
    libzip-dev libpng-dev libonig-dev \
    libxml2-dev libicu-dev \
    && docker-php-ext-install \
    pdo pdo_mysql mbstring zip xml bcmath intl \
    && apt clean && rm -rf /var/lib/apt/lists/*

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

RUN cat > /etc/nginx/sites-available/default <<'NGINXEOF'
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
NGINXEOF

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]
