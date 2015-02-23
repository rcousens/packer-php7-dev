php-fpm:
  pkg.latest:
    - names:
      - php-fpm
      - php-cli
      - php-devel
      - php-intl
      - php-mbstring
      - php-mcrypt      
      - php-pdo
      - php-pgsql
      - php-pecl-redis
      - php-pecl-xdebug
      - php-pecl-zendopcache
  service.running:
    - enable: true
    - watch:
      - pkg: php-fpm
      - file: /etc/php.ini
      - file: /etc/php-fpm.d/www.conf
      - file: /etc/php.d/xdebug.ini

php-ini:
  file.managed:
    - name: /etc/php.ini
    - source: salt://_files/php/php.ini
    - template: jinja
    - require:
      - pkg: php-fpm

php-fpm-conf:
  file.managed:
    - name: /etc/php-fpm.d/www.conf
    - source: salt://_files/php-fpm/www.conf
    - template: jinja
    - require:
      - pkg: php-fpm

xdebug-ini:
  file.managed:
    - name: /etc/php.d/xdebug.ini
    - source: salt://_files/php/xdebug.ini
    - template: jinja
    - require:
      - pkg: php-fpm

/var/lib/php/session:
  file:
    - directory
    - user: apache
    - group: apache
    - makedirs: true
