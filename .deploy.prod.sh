set -e

echo "Deployment Started"

cd /var/www || exit
git pull origin master
docker compose down && docker compose up -d

if [ ! -f /var/www/first_run ]; then
    echo "Running composer install..."
    composer install --optimize-autoloader

    echo "Running npm install..."
    /usr/bin/node /usr/bin/npm install

    echo "Running php artisan key:generate"
    php artisan key:generate

    echo "Creating first_run file..."
    touch /var/www/first_run

else
    echo "first_run file already exists. Skipping initial setup..."


    composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
    php artisan migrate
    php artisan storage:link
    php artisan optimize:clear
    php artisan horizon:terminate
    php artisan config:cache
    php artisan route:cache
    php artisan event:cache
    php artisan optimize
    /usr/bin/node /usr/bin/npm install
    /usr/bin/node /usr/bin/npm run build

fi
