lcov-src:
  git.latest:
    - name: https://github.com/linux-test-project/lcov.git
    - rev: v1.11
    - target: /home/vagrant/lcov
    - user: vagrant

lcov-make:
  cmd.wait:
    - name: make install
    - cwd: /home/vagrant/lcov
    - user: root
    - watch:
      - git: lcov-src
