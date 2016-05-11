FROM php:7.0.2-fpm
MAINTAINER Petter Kjelkenes <kjelkenes@gmail.com>

RUN apt-get update \
  && apt-get install -y \
    git \
    cron \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev

RUN docker-php-ext-configure \
  gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/

RUN docker-php-ext-install \
  gd \
  intl \
  mbstring \
  mcrypt \
  pdo_mysql \
  xsl \
  zip

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.0.0-alpha11

RUN echo "*/1 * * * * su -c \"/usr/local/bin/php /src/update/cron.php >> /src/var/log/magento.cron.log\" -s /bin/sh www-data" | crontab - \
  && (crontab -l ; echo "*/1 * * * * su -c \"/usr/local/bin/magento-varnish-cron >> /src/var/log/aws-magento-varnish.cron.log\" -s /bin/sh www-data") | crontab - \
  && (crontab -l ; echo "*/1 * * * * su -c \"/usr/local/bin/php /src/bin/magento-php cron:run >> /src/var/log/magento.cron.log\" -s /bin/sh www-data") | crontab - \
  && (crontab -l ; echo "*/1 * * * * su -c \"/usr/local/bin/php /src/bin/magento-php setup:cron:run >> /src/var/log/magento.cron.log\" -s /bin/sh www-data") | crontab -

ENV PHP_MEMORY_LIMIT 2G
ENV PHP_PORT 9000
ENV PHP_PM dynamic
ENV PHP_PM_MAX_CHILDREN 10
ENV PHP_PM_START_SERVERS 4
ENV PHP_PM_MIN_SPARE_SERVERS 2
ENV PHP_PM_MAX_SPARE_SERVERS 6
ENV APP_MAGE_MODE production

ENV WEBSITE_UNSECURE_URL "http://localhost"
ENV WEBSITE_SECURE_URL "https://localhost"
ENV PHP_SENDMAIL_PATH /usr/sbin/ssmtp -t
ENV RDS_HOSTNAME ""
ENV RDS_DB_NAME ebdb
ENV RDS_USERNAME ""
ENV RDS_PASSWORD ""
ENV MAGENTO_BACKEND_FRONTNAME admin
ENV MAGENTO_LANGUAGE en_US
ENV MAGENTO_TIMEZONE "Europe/Oslo"
ENV MAGENTO_CURRENCY "NOK"
ENV MAGENTO_ADMIN_FIRSTNAME "Admin"
ENV MAGENTO_ADMIN_LASTNAME "Admin"
ENV MAGENTO_ADMIN_EMAIL "admin@example.com"
ENV MAGENTO_ADMIN_USERNAME admin
ENV MAGENTO_ADMIN_PASSWORD Admin321123
ENV MAGENTO_USE_REWRITES 1
ENV MEDIA_S3_ACCESS_KEY ""
ENV MEDIA_S3_SECRET_KEY ""
ENV MEDIA_S3_BUCKET ""
ENV MEDIA_S3_REGION "eu-west-1"
ENV ELASTICACHE_CONNECTION ""


ENV SSMTP_ROOT "google@gmail.com"
ENV SSMTP_MAILHUB smtp.gmail.com:587
ENV SSMTP_HOSTNAME smtp.gmail.com:587
ENV SSMTP_USE_STARTTLS YES
ENV SSMTP_AUTHUSER "google@gmail.com"
ENV SSMTP_AUTHPASS "mysecretpass"
ENV SSMTP_AUTHMETHOD LOGIN
ENV SSMTP_FROM_LINE_OVERRIDE YES



ENV COMPOSER_HOME /home/composer
ENV GITHUB_OAUTH_TOKEN ""
ENV MAGENTO_REP_USERNAME ""
ENV MAGENTO_REP_PASSWORD ""


COPY resources/conf/php.ini /usr/local/etc/php/
COPY resources/conf/php-fpm.conf /usr/local/etc/
COPY resources/bin/* /usr/local/bin/

RUN mkdir -p /home/composer
COPY resources/conf/auth.json /home/composer/

# Create dir for www home user, to store .ssh keys.
RUN mkdir -p /var/www

WORKDIR /src

RUN apt-get update && apt-get install -y gcc g++ unzip jq
RUN curl -o clusterclient-aws-php7.zip https://s3.amazonaws.com/elasticache-downloads/ClusterClient/PHP-7.0/latest-64bit && \
     unzip clusterclient-aws-php7.zip && \
     cp artifact/amazon-elasticache-cluster-client.so "$(php -r 'echo ini_get("extension_dir");')" && \ 
     docker-php-ext-enable amazon-elasticache-cluster-client

RUN apt-get update && apt-get install -y mysql-client ssmtp
COPY resources/conf/ssmtp.conf /etc/ssmtp/ssmtp.conf

CMD ["/usr/local/bin/start"]
