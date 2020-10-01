FROM alpine:3.12
LABEL Maintainer="Tim de Pater <code@trafex.nl>" \
      Description="Lightweight container with Nginx 1.18 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini
COPY config/php-fpm.conf /etc/php7/php-fpm.conf


# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN addgroup -g 1000 web && \
  adduser -u 1000 -h /home/web -s /bin/bash -G web -D web

# Setup document root
RUN mkdir -p /home/web/www /home/web/log

RUN touch /home/web/log/error.log /home/web/log/access.log /home/web/log/php-fpm.log

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R web.web /home/web/ && \
  chown -R web.web /run && \
  chown -R web.web /var/lib/nginx && \
  chmod -R o+rw /var/log/nginx

# Switch to use a non-root user from here on
USER web

# Add application
WORKDIR /home/web/www
COPY --chown=web src/ /home/web/www

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
