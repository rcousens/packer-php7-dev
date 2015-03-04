# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "rcousens/php7-dev-c7"
  # config.vm.box_url = "build/virtualbox/vagrant/php7-dev-c7-x86_64.box"

  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.name = "php7-dev-c7"
  end

  config.vm.network "forwarded_port", guest: 80, host:10001 # nginx 
  config.vm.network "forwarded_port", guest: 5432, host:10002 # postgresql

  config.vm.network "private_network", type: "dhcp"

  config.vm.synced_folder "salt/roots/salt", "/srv/salt"
  config.vm.synced_folder "salt/roots/pillar", "/srv/pillar"
  
  config.vm.provision :salt do |salt|    
    salt.always_install = false
    salt.colorize = true
    salt.install_args = "v2015.2"
    salt.install_type = "git"    
    salt.log_level = "info"
    salt.minion_config = "salt/minion"
    salt.run_highstate = true
    salt.verbose = true
  end
end
