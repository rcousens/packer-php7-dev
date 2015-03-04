nginx:
  pkg.latest:
    - refresh: true
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/conf.d/dev.conf
      - pkg: nginx

/srv/www/dev/web:
  file:
    - directory
    - user: vagrant
    - group: vagrant
    - makedirs: true

nginx-conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://_files/nginx/conf/nginx.conf
    - template: jinja
    - require:
      - pkg: nginx

nginx-vhost-dev:
  file.managed:
    - name: /etc/nginx/conf.d/dev.conf
    - source: salt://_files/nginx/vhosts/dev.conf
    - template: jinja
    - require:
      - file: nginx-conf
      - pkg: nginx

nginx-phpinfo:
  file.managed:
    - name: /srv/www/dev/web/phpinfo.php
    - source: salt://_files/web/phpinfo.php
    - unless: test -f /srv/www/dev/web/app.php
    - require:
      - file: /srv/www/dev/web
