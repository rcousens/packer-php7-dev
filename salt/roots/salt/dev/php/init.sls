php-src:
  git.latest:
    - name: https://github.com/php/php-src
    - rev: master
    - target: /home/vagrant/php-src
    - user: vagrant

php-buildconf:
  cmd.wait:
    - name: ./buildconf
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant    
    - require:
      - git: php-src
    - watch:
      - git: php-src

php-configure:
  cmd.wait:
    - name: ./configure --enable-debug --enable-fpm --with-fpm-user=nginx --with-fpm-group=nginx --with-fpm-systemd --enable-maintainer-zts --with-openssl --prefix=/usr/local
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - watch:
      - cmd: php-buildconf

php-make-clean:
  cmd.wait:
    - name: make clean
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - watch:
      - cmd: php-configure

php-make:
  cmd.wait:
    - name: make
    - cwd: /home/vagrant/php-src
    - user: vagrant
    - group: vagrant
    - watch:
      - cmd: php-make-clean

php-make-install:
  cmd.wait:
    - name: make install
    - cwd: /home/vagrant/php-src
    - user: root
    - group: root
    - watch:
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
    - source: /home/vagrant/php-src/sapi/fpm/www.conf
    - makedirs: true
    - watch:
      - cmd: php-make-install

php-fpm-service-systemd:
  file.copy:
    - name: /usr/lib/systemd/system/php-fpm.service
    - source: /home/vagrant/php-src/sapi/fpm/php-fpm.service

php-fpm:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: php-fpm-service-systemd


