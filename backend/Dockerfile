FROM serversideup/php:8.3-fpm-nginx-alpine

WORKDIR /var/www/html

COPY . .

RUN composer install
RUN php artisan config:clear
RUN php artisan view:clear

CMD [ "composer", "migrate-and-schedule" ]