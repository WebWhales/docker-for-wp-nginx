FROM php:8-fpm

# Install the packages we need
RUN apt-get update && apt-get -y install \
    autoconf \
    curl \
    g++ \
    gcc \
    git \
    libbz2-dev \
    libc-client-dev \
    libc-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    libpng-dev \
    libwebp-dev \
    libreadline-dev \
    libssl-dev \
    libxslt1-dev \
    libzip-dev \
    make \
    nginx \
    openssl \
    pkg-config \
    supervisor \
    unzip \
    wget \
    zip \
    zlib1g-dev

RUN mkdir -p /run/php && \
    mkdir -p /var/log/nginx && \
    mkdir -p /var/log/php && \
    mkdir -p /var/log/supervisor

# Install PHP packages
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j$(nproc) \
      bcmath \
      bz2 \
      calendar \
      exif \
      gd \
      gettext \
      iconv \
      intl \
      mysqli  \
      opcache \
      pdo_mysql \
      soap \
      sockets \
      xsl \
      zip
RUN pecl install redis xdebug && docker-php-ext-enable redis
RUN yes '' | pecl install imagick && docker-php-ext-enable imagick
RUN docker-php-ext-enable xdebug
RUN docker-php-source delete; \
    apt-get autoremove --purge -y && apt-get autoclean -y && apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/* /var/tmp/*

# Install the packages we need to persist. We do this here, because unused packages are removed above
RUN apt-get update && apt-get -y install \
    mariadb-client \
    nano \
    unzip


# Copy nginx config
RUN mkdir -p /var/www/dummy
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/default-site.conf /etc/nginx/sites-available/default
COPY config/nginx/conf.d/. /etc/nginx/conf.d/
COPY config/nginx/snippets/. /etc/nginx/snippets/


# Copy php config
COPY config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf
RUN { \
        echo 'xdebug.mode = debug'; \
        echo 'xdebug.discover_client_host = false'; \
        echo 'xdebug.client_host = host.docker.internal'; \
        echo 'xdebug.start_with_request = trigger'; \
        echo 'xdebug.idekey = PHPSTORM'; \
    } >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini


# Copy suporvisor config
COPY config/supervisor/supervisord.conf /etc/supervisord.conf


# Add an SSL certificate for *.localhost
COPY config/ssl/localhost.ext /etc/ssl/localhost.ext
RUN openssl req -x509 \
    -out /etc/ssl/localhost.crt \
    -keyout /etc/ssl/localhost.key \
    -newkey rsa:2048 -nodes -sha256 -days 1024 \
    -subj "/C=NL/ST=Zuid-Holland/O=Localhost/CN=localhost" \
    -extensions EXT \
    -config /etc/ssl/localhost.ext


#
# Install Composer
#
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#
# Install NodeJS
#
RUN curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs npm


#
# Installing gulp, yarn and n globally
#
RUN npm -g install gulp-cli gulp yarn n


#
# Install PHPUnit
#
RUN curl https://phar.phpunit.de/phpunit.phar -L > phpunit.phar \
  && chmod +x phpunit.phar \
  && mv phpunit.phar /usr/local/bin/phpunit


#
# Change the necessary user rights
#
RUN chown -R www-data: /var/www
RUN chmod -R 0755 /var/www


ENV PATH "$PATH:$HOME/.composer/vendor/bin:/root/.composer/vendor/bin:/usr/src/app/node_modules/.bin"


EXPOSE 80 443


# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]