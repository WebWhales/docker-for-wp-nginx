FROM php:7.3-fpm

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
    libreadline-dev \
    libssl-dev \
    libxslt1-dev \
    libzip-dev \
    make \
    nano \
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

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
    docker-php-ext-install -j$(nproc) gd; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j$(nproc) intl; \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        bz2 \
        calendar \
        exif \
        gettext \
        iconv \
        mysqli  \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip; \
    pecl install redis && docker-php-ext-enable redis; \
    yes '' | pecl install imagick && docker-php-ext-enable imagick \
    apt-get autoremove --purge -y && apt-get autoclean -y && apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/* /var/tmp/*


# Copy nginx config
RUN mkdir -p /var/www/dummy
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/default-site.conf /etc/nginx/sites-available/default
COPY config/nginx/conf.d/. /etc/nginx/conf.d/
COPY config/nginx/snippets/. /etc/nginx/snippets/


# Copy php config
COPY config/php/www.conf /usr/local/etc/php-fpm.d/www.conf
RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf


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
RUN export PATH="$PATH:$HOME/.composer/vendor/bin"


#
# Install NodeJS
#
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get update && apt-get install -y nodejs
RUN nodejs -v
RUN export PATH="$PATH:/usr/src/app/node_modules/.bin"


#
# Installing Yarn globally
#
RUN npm -g install yarn


#
# Install Gulp globally
#
RUN npm install -g gulp-cli gulp


#
# Install PHPUnit
#
RUN curl https://phar.phpunit.de/phpunit.phar -L > phpunit.phar \
  && chmod +x phpunit.phar \
  && mv phpunit.phar /usr/local/bin/phpunit


#
# Install php-cs-fixer
#
RUN composer global require friendsofphp/php-cs-fixer


EXPOSE 80 443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]