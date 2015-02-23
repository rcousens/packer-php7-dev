redis:
  pkg.latest:
    - refresh: true
  service.running:
    - enable: true
    - watch:
      - pkg: redis
      - file: /etc/redis.conf

redis-conf:
  file.managed:
    - name: /etc/redis.conf
    - source: salt://_files/redis/redis.conf
    - template: jinja
    - require:
      - pkg: redis
