FROM serversideup/php:8.3-fpm-nginx-alpine

WORKDIR /var/www/html

COPY --chown=www-data:www-data . .

RUN composer install
RUN php artisan config:clear
RUN php artisan view:clear

CMD [ "composer", "migrate-and-schedule" ]