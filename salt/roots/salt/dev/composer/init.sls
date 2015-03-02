# http://docs.saltstack.com/en/latest/ref/states/all/salt.states.composer.html
include:
  - php

get-composer:
  cmd.run:
    - name: 'CURL=`which curl`; $CURL -sS https://getcomposer.org/installer | /usr/local/bin/php'
    - unless: test -f /usr/local/bin/composer
    - onlyif: test -f /usr/local/bin/php
    - cwd: /root/
    - require:
      - sls: php

install-composer:
  cmd.wait:
    - name: mv /root/composer.phar /usr/local/bin/composer
    - cwd: /root/
    - watch:
      - cmd: get-composer

update-composer:
  cmd.run:
    - name: 'PATH=$PATH:/usr/local/bin; composer self-update'
    - onlyif: test -f /usr/local/bin/composer
