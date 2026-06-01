#!/bin/bash

set -e

cat > /var/www/html/.env <<'ENVEOF'
APP_NAME=GameTime
APP_ENV=production
APP_KEY=base64:I1EucQ101zqjy5v93TTxZRxZTK7J6PLmQ7bT5lUwdHo=
APP_DEBUG=false
APP_URL=https://ecsphp.mathesh.tech
ASSET_URL=https://ecsphp.mathesh.tech

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=mathesh-manual-php-ecs-db.cvys2qsqc8bx.ap-south-1.rds.amazonaws.com
DB_PORT=3306
DB_DATABASE=tictactoe
DB_USERNAME=admin
DB_PASSWORD=password

CACHE_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=dropdeckmail@gmail.com
MAIL_PASSWORD="faud psqq avmi phce"
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=dropdeckmail@gmail.com
MAIL_FROM_NAME=GameTime
VITE_APP_NAME=GameTime
ENVEOF

echo ".env written:"
cat /var/www/html/.env

php artisan optimize:clear || true
php artisan config:cache    || true
php artisan route:cache     || true
php artisan view:cache      || true
php artisan migrate --force || true

php-fpm -D
nginx -g "daemon off;"


