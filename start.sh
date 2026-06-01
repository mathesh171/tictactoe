#!/bin/bash
set -e

# Write .env from ECS task definition environment variables
cat > /var/www/html/.env <<ENVEOF
APP_NAME=${APP_NAME:-GameTime}
APP_ENV=${APP_ENV:-production}
APP_KEY=${APP_KEY}
APP_DEBUG=${APP_DEBUG:-false}
APP_URL=${APP_URL}
ASSET_URL=${ASSET_URL}

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE}
DB_USERNAME=${DB_USERNAME}
DB_PASSWORD=${DB_PASSWORD}

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
ENVEOF

# Clear old caches
php artisan optimize:clear || true

# Cache config, routes, views
php artisan config:cache || true
php artisan route:cache  || true
php artisan view:cache   || true

# Run migrations
php artisan migrate --force || true

# Start php-fpm in background, then nginx in foreground
php-fpm -D
nginx -g "daemon off;"
