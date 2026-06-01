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

COPY . /var/www/html

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN mkdir -p storage/logs bootstrap/cache \
    && touch storage/logs/laravel.log \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

COPY nginx.conf /etc/nginx/sites-available/default

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]
