# PHP 7 Development Box

This repository houses the configuration scripts necessary to build a CentOS 7 based box suitable for PHP7 testing and extension development.

 - Clones latest PHP repository on master branch 
 - Builds from source
 - Installs the compiled binaries as SAPI FPM
 - Includes nginx and PostgreSQL

The configuration is defined in salt state files that can be run by either packer or vagrant provision. To build the box yourself, you will require a CentOS 7 iso that has the minimum software as specified in the kickstarter config or if your internet connection is sufficiently fast you could point it to an iso to download.

Packer supports producing VirtualBox and VMware images. Currently the packer.json specifies an output virtualbox machine as I don't have a license for VMware.

## Packer

> [Packer] is a free and open source tool for creating golden images for multiple platforms from a single source configuration.

## SaltStack

> [SaltStack] is an extremely fast and scalable systems and configuration management software for predictive orchestration, cloud and data center automation, server provisioning, application deployment and more.

# Configuration Files

## Anaconda KickStarter

Specifies the CentOS 7 installation options and prepares passwordless sudo for vagrant. See [ks.cfg].

## Packer Provisioning

Installs VirtualBox Guest additions and cleans up post installation. See [scripts] and [packer.json].

# Included Components

## PHP7

PHP7 is the next major release version of PHP. It includes significant performance improvements and additions to the language.

## nginx

Nginx is installed and configured to serve a website from /srv/www/dev/web. The default dev.conf in /etc/nginx/conf.d/dev.conf contains the configuration.

## PostgreSQL

PostgreSQL is configured to accept md5 connections from all hosts (I will tighten the security up in the future) with a superuser configured with the login dbuser and password dbuser.

---

# Instructions

## Quick Setup


### Requirements
* [Vagrant]

### Instructions

Clone this repo into a local directory:
```sh
$ git clone https://github.com/rcousens/packer-php7-dev.git
```
Change directory to where the repo was cloned and launch the vagrant box:
```sh
$ vagrant up
```
From the host machine:
nginx is listening on http://localhost:10001.
PostgreSQL is listening on tcp://localhost:10002.

To access the virtual machine:
```sh
$ vagrant ssh
```

## Build Box Yourself
TODO

# Things You Can Do With the Development Box

## Run PHP7 in a development environment

Install your website under /srv/www/dev/web with a front controller app.php or a default file index.php.

## Tutorials
* [Debug a PHP extension][1]

License
----

MIT

[Packer]:https://www.packer.io/
[SaltStack]:http://saltstack.com/
[ks.cfg]:https://github.com/rcousens/packer-php7-dev/blob/master/packer/http/ks.cfg
[scripts]:https://github.com/rcousens/packer-php7-dev/tree/master/packer/scripts
[packer.json]:https://github.com/rcousens/packer-php7-dev/blob/master/packer/packer.json
[Vagrant]:https://www.vagrantup.com/
[1]:https://github.com/rcousens/packer-php7-dev/blob/master/doc/01-debug-php-extension.md

