set -e

echo "Deployment Started"

docker compose down && docker compose up -d

git pull origin master

if [ ! -f /var/www/first_run ]; then
    echo "Running composer install..."
    docker compose exec -it app composer install --optimize-autoloader
    docker compose exec -it app php artisan migrate:fresh

    echo "Running npm install..."
    docker compose exec -it app /usr/bin/node /usr/bin/npm install

    echo "Running php artisan key:generate"
    docker compose exec -it app php artisan key:generate

    echo "Creating first_run file..."
    docker compose exec -it app touch /var/www/first_run

else
    echo "first_run file already exists. Skipping initial setup..."


    docker compose exec -it app composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist
    docker compose exec -it app php artisan migrate --force
    docker compose exec -it app php artisan storage:link
    docker compose exec -it app php artisan optimize:clear
    docker compose exec -it app php artisan optimize

    docker compose exec -it app /usr/bin/node /usr/bin/npm install
    docker compose exec -it app /usr/bin/node /usr/bin/npm run build

fi
