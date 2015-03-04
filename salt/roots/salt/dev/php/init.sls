include:
  - lcov

php-src:
  git.latest:
    - name: https://github.com/php/php-src.git
    - rev: master
    - target: /home/vagrant/php-src
    - user: vagrant

php-make-distclean:
  cmd.wait:
    - name: make distclean
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - onlyif: test -f /home/vagrant/php-src/Makefile
    - onchanges:
      - git: php-src

php-buildconf:
  cmd.run:
    - name: ./buildconf
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant    
    - watch:
      - cmd: php-make-distclean
    - require:
      - git: php-src

php-configure:
  cmd.run:
    - name: ./configure --enable-debug --enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx --with-fpm-systemd --enable-maintainer-zts --with-openssl --with-curl --enable-zip --enable-intl --enable-mbstring --enable-gcov --prefix=/usr/local --sbindir=/usr/local/sbin --sysconfdir=/usr/local/etc --with-config-file-scan-dir=/usr/local/lib/php/config
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - require:
      - cmd: php-buildconf
      - sls: lcov

php-make:
  cmd.run:
    - name: make
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - require:
      - cmd: php-make-distclean

php-make-install:
  cmd.run:
    - name: make install
    - cwd: /home/vagrant/php-src
    - user: root
    - group: root
    - require:
      - cmd: php-make

php-ini:
  file.copy:
    - name: /usr/local/lib/php.ini
    - source: /home/vagrant/php-src/php.ini-development
    - makedirs: true
    - watch:
      - cmd: php-make-install

php-fpm-conf:
  file.copy:
    - name: /usr/local/etc/php-fpm.conf
    - source: /usr/local/etc/php-fpm.conf.default
    - makedirs: true
    - watch:
      - cmd: php-make-install

php-www-conf:
  file.copy:
    - name: /usr/local/etc/php-fpm.d/www.conf
    - source: /usr/local/etc/php-fpm.d/www.conf.default
    - makedirs: true
    - watch:
      - cmd: php-make-install

php-fpm-service-systemd:
  file.copy:
    - name: /usr/lib/systemd/system/php-fpm.service
    - source: /home/vagrant/php-src/sapi/fpm/php-fpm.service
    - watch:
      - cmd: php-make-install

php-fpm:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: php-fpm-service-systemd

php-config-dir:
  file:
    - directory
    - name: /usr/local/lib/php/config
    - user: root
    - group: root
    - makedirs: true

php-opcache-ini:
  file.managed:
    - name: /usr/local/lib/php/config/opcache.ini
    - source: salt://_files/php/opcache.ini
    - require:
      - file: php-config-dir