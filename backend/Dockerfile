FROM serversideup/php:8.3-fpm-nginx-alpine

WORKDIR /var/www/html

COPY --chown=www-data:www-data . .

RUN mkdir -p /var/www/html/storage/sqlite && \
    chown -R www-data:www-data /var/www/html/storage && \
    chmod -R 775 /var/www/html/storage

USER www-data

RUN composer install --no-dev --no-interaction --no-progress --no-suggest
RUN php artisan config:clear
RUN php artisan view:clear

CMD [ "composer", "migrate" ]
