FROM andrefernandes86/demo-apachestruts-attacker-web

LABEL maintainer="AF"

RUN apt-get update -y
RUN apt-get install wget -y
RUN apt-get install curl -y

RUN curl https://files.trendmicro.com/products/CloudOne/ApplicationSecurity/1.0.2/agent-php/trend_app_protect-x86_64-Linux-gnu-4.1.11-20151012.so > trend_app_protect-x86_64-Linux-gnu-4.1.11-20151012.so
RUN cp trend_app_protect-x86_64-Linux-gnu-4.1.11-20151012.so "$(php -r 'echo ini_get ("extension_dir");')"/trend_app_protect.so

RUN echo "; Enable the extension" >> /etc/php/7.0/apache2/php.ini
RUN echo "extension = trend_app_protect.so" >> /etc/php/7.0/apache2/php.ini
RUN echo "; Add key and secret from the Application Protection dashboard" >> /etc/php/7.0/apache2/php.ini
RUN echo "trend_app_protect.key = Your-C1AS-Key" >> /etc/php/7.0/apache2/php.ini
RUN echo "trend_app_protect.secret = Your-C1AS-Secret" >> /etc/php/7.0/apache2/php.ini

EXPOSE 80
