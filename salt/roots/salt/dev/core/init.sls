include:
  - nginx
  - php

vagrant-sudoers:
  file.managed:
    - name: /etc/sudoers.d/vagrant
    - source: salt://_files/sudo/vagrant
    - template: jinja
    - order: last

set-permissions:
  cmd.run:
    - name: 'SETFACL=`which setfacl`; $SETFACL -R -m u:vagrant:rwX /srv/www; $SETFACL -dR -m u:vagrant:rwX /srv/www'
    - order: last
