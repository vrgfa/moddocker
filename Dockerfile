FROM php:7.2.0-fpm
MAINTAINER Oleksandr Sumtsov <oleksandr.sumtsov@gmail.com>

ENV PHP_EXT_XDEBUG_VERSION "2.7.2"


RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  sendmail-bin \
  sendmail \
  sudo \
  libbz2-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  libfreetype6-dev \
  libgeoip-dev \
  wget \
  libgmp-dev \
  libmagickwand-dev \
  libmagickcore-dev \
  libc-client-dev \
  libkrb5-dev \
  libicu-dev \
  libldap2-dev \
  libmcrypt-dev \
  libpspell-dev \
  librecode0 \
  librecode-dev \
  #libsodium-dev \
  libssh2-1 \
  libssh2-1-dev \
  libtidy-dev \
  libxslt1-dev \
  libxml2-dev \
  libmemcached-dev \
  ruby \
  cron \
  libyaml-dev

RUN gem install capistrano -v 3.4.1

RUN curl -O https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz \
  && tar xfvz libsodium-1.0.18.tar.gz \
  && cd libsodium-1.0.18 \
  && ./configure \
  && make && make install \
  && pecl install -f libsodium

RUN build_packages="libpng-dev libfreetype6-dev libjpeg62-turbo-dev libxml2-dev libxslt1-dev libmemcached-dev libmcrypt-dev" \
    && apt-get update && apt-get install -y $build_packages \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install soap \
    && yes | pecl install xdebug-$PHP_EXT_XDEBUG_VERSION && docker-php-ext-enable xdebug \
    && docker-php-ext-install xsl \
    && docker-php-ext-install zip \
    && docker-php-ext-install intl \
    && docker-php-ext-install sodium \
    && docker-php-ext-install calendar\
    && docker-php-ext-configure calendar \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN pecl install imagick
RUN docker-php-ext-enable imagick

RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin && \
        echo "alias composer='composer'" >> /root/.bashrc && \
        composer

RUN pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

ENV ION_CUBE_PHP_VERSION "7.2"

RUN PHP_EXTENSION_DIR="$(php-config --extension-dir)" bash -c 'curl http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o /ioncube_loaders_lin_x86-64.tar.gz && \
    tar -xzvf /ioncube_loaders_lin_x86-64.tar.gz -C / && \
    cp "/ioncube/ioncube_loader_lin_${ION_CUBE_PHP_VERSION}.so" $PHP_EXTENSION_DIR && \
    echo "zend_extension=${PHP_EXTENSION_DIR}/ioncube_loader_lin_${ION_CUBE_PHP_VERSION}.so" > /usr/local/etc/php/conf.d/00-ioncube.ini && \
    rm -rf /ioncube /ioncube_loaders_lin_x86-64.tar.gz'


ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
