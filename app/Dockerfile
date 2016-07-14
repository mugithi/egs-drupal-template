#Built from Ubuntu
FROM ubuntu:14.04
#

# #Install php deps, mysql client,
RUN apt-get -y update && apt-get install -y \
nginx \
nginx-extras \
php5-fpm \
drush \
mysql-client \
php5-gd \
php-db \
php5-curl \
php5-cgi \
php5-cli \
git \
wget

RUN rm -rf /files/ && mkdir -p /files/ && cd /files/ && git clone https://github.com/mugithi/drupal-configuration.git .  && cd /files/build && chmod 777 entrypoint.sh

ENTRYPOINT ["/files/build/entrypoint.sh"]

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
