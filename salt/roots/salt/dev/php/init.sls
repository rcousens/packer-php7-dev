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
    - name: ./configure --enable-debug --enable-fpm --with-fpm-systemd --enable-maintainer-zts
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
