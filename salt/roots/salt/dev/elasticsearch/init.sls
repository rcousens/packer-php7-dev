import-es-key:
  cmd.run:
    - name: 'RPM=`which rpm`; $RPM --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch'
    - unless: test -f /usr/local/bin/composer
    - cwd: /root/

es-repo:
  file.managed:
    - name: /etc/yum.repos.d/elasticsearch.repo
    - source: salt://_files/elasticsearch/elasticsearch.repo
    - template: jinja

java-jre:
  pkg.latest:
    - name: java-1.7.0-openjdk
    - refresh: true

elasticsearch:
  pkg.latest:
    - refresh: true
  service.running:
    - enable: true
    - restart: true
  require:
    - pkg: java-jre