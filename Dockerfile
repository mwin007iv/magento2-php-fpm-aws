# This is a comment
FROM mageinferno/magento2-php:7.0.2-fpm-1
MAINTAINER Petter Kjelkenes <kjelkenes@gmail.com>



RUN apt-get update && apt-get install -y unzip
RUN curl -o clusterclient-aws-php7.zip https://s3.amazonaws.com/elasticache-downloads/ClusterClient/PHP-7.0/latest-64bit && \
     unzip clusterclient-aws-php7.zip && \
     cp artifact/amazon-elasticache-cluster-client.so "$(php -r 'echo ini_get("extension_dir");')" && \ 
     docker-php-ext-enable amazon-elasticache-cluster-client


