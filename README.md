# Phalcon_devtools_3.2.13_install
>
In development, we use a virtual machine with CentOS to run docker.  
But locally(namely in CentOS,not in the docker containers), we use Phalcon-devtoos and PHP_CodeSniffer.  
This script just install docker, docker-compose, Phalcon-devtoos and PHP_CodeSniffer locally.  

# Installation
```
cd ~
git clone https://github.com/412445773/Phalcon_devtools_3.2.13_install.git
cd ~/initialize_env
chmod u+x initialize_env.sh install_imagick.exp
. ./initialize_env.sh
```

# Usage
```
php -v
phpcs -h
phpcbf -h
phalcon commands
docker-compose version   
```
