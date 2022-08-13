FROM ubuntu AS base

WORKDIR /

RUN apt update -y

RUN apt install apache2 -y

RUN mkdir -p /var/lock/apache2
RUN mkdir -p /var/run/apache2


FROM base AS web

ENV APACHE_RUN_USER www-data

ENV APACHE_RUN_GROUP www-data

ENV APACHE_PID_FILE /var/run/apache2.APACHE_PID_FILE

ENV APACHE_RUN_DIR /var/run/apache2

ENV APACHE_LOCK_DIR /var/log/apache2

ENV APACHE_LOG_DIR /var/log/apache2

ENV LANG C

WORKDIR /var/www/html

COPY . . 

CMD ["/usr/sbin/apache2","-D","FOREGROUND"]
EXPOSE 80