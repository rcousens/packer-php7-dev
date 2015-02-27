include:
  - nginx
  - php

vagrant-sudoers:
  file.managed:
    - name: /etc/sudoers.d/vagrant
    - source: salt://_files/sudo/vagrant
    - template: jinja
    - order: last

debuginfo-install:
  cmd.run:
    - name: debuginfo-install glibc-2.17-55.el7_0.5.x86_64 libxml2-2.9.1-5.el7_0.1.x86_64 nss-softokn-freebl-3.16.2.3-1.el7_0.x86_64 xz-libs-5.1.2-8alpha.el7.x86_64 zlib-1.2.7-13.el7.x86_64
    - order: last

set-permissions:
  cmd.run:
    - name: 'SETFACL=`which setfacl`; $SETFACL -R -m u:apache:rwX -m u:vagrant:rwX /srv/www; $SETFACL -dR -m u:apache:rwX -m u:vagrant:rwX /srv/www'
    - order: last
