#!/bin/sh
#set -ex
PHP_VERSION=7.2.12
PHP_SHA256=d7cabdf4e51db38121daf0d494dc074743b24b6c79e592037eeedd731f1719dd
CPHALCON_VERSION=3.4.1
PHALCON_DEVTOOLS_VERSION=3.2.13
scripts_dir=$(dirname $(readlink -f "$0"))
scripts_dir=$(cd "$(dirname "$0")";pwd)
#修改CentOS源，epel源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum remove -y docker docker-common docker-selinux docker-engine
yum clean all
yum makecache
yum update -y
yum install -y re2c openssl-devel libxml2-devel curl-devel libwebp-devel libjpeg-devel libpng-devel ImageMagick-devel autoconf automake git yum-utils device-mapper-persistent-data lvm2 expect
yum remove docker docker-common docker-selinux docker-engine
#设置docker源
wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
yum makecache fast
yum install -y docker-ce docker-compose
systemctl enable docker
systemctl restart docker
if [ -e /usr/local/src/php-${PHP_VERSION}.tar.gz ];then
    php_sha256=$(sha256sum /usr/local/src/php-${PHP_VERSION}.tar.gz)
    php_sha256=($php_sha256)
    php_sha256=${php_sha256[0]}
    if [ "$php_sha256" != "$PHP_SHA256" ];then
        unlink /usr/local/src/php-${PHP_VERSION}.tar.gz
    fi
fi
if [ ! -e /usr/local/src/php-${PHP_VERSION}.tar.gz ];then
    wget -O /usr/local/src/php-${PHP_VERSION}.tar.gz https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz
    tar -xf /usr/local/src/php-${PHP_VERSION}.tar.gz -C /usr/local/
    cd /usr/local/php-${PHP_VERSION}
    make clean
    ./configure \
        --with-libdir=/lib64 \
        --with-config-file-path=/usr/local/etc/php \
        --with-config-file-scan-dir=/usr/local/etc/php/conf.d \
        --enable-cli \
        --disable-cgi \
        --disable-fpm \
        --enable-phar \
        --with-pear  \
        --disable-all \
        --enable-xml \
        --enable-libxml \
        --enable-mysqlnd \
        --with-gd \
        --with-webp-dir --with-jpeg-dir \
        --with-curl \
        --enable-fileinfo \
        --with-gettext \
        --enable-json \
        --enable-mbstring \
        --with-openssl \
        --enable-pdo \
        --with-pdo_mysql \
        --enable-tokenizer \
        --enable-xmlwriter \
        --enable-simplexml \
        --enable-hash \
        --enable-session
    make && make install
fi
[ ! -d /var/log/php ] && mkdir /var/log/php
mkdir -p /usr/local/etc/php
mkdir -p /usr/local/etc/php/conf.d
cp /usr/local/php-${PHP_VERSION}/php.ini-development /usr/local/etc/php/php.ini
#设置时区
echo 'date.timezone = Asia/Shanghai' > /usr/local/etc/php/conf.d/date_timezone.ini
#设置error_log
echo 'error_log = /var/log/php/php_errors.log' > /usr/local/etc/php/conf.d/error_log.ini

#更新channel,我也不知道为什么要更新,反正不更新就有提示
pecl channel-update pecl.php.net
#安装imagick
pecl list | grep -q imagick
imagick_installed=$?
if [ $imagick_installed -ne 0 ];then
    expect -f ${scripts_dir}/install_imagick.exp
fi
echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini
#安装psr
pecl list | grep -q psr
psr_installed=$?
[ $psr_installed -ne 0 ] && pecl install psr
echo 'extension=psr.so' > /usr/local/etc/php/conf.d/psr.ini

[ ! -d /usr/local/src/cphalcon ] && cd /usr/local/src && git clone https://github.com/phalcon/cphalcon.git
[ ! -d /usr/local/src/phalcon-devtools ] && cd /usr/local/src && git clone https://github.com/phalcon/phalcon-devtools.git

#安装cphalcon
php -m | grep -q phalcon
phalcon_installed=$?
if [ $phalcon_installed -ne 0 ];then
    cd /usr/local/src/cphalcon
    git checkout tags/v${CPHALCON_VERSION} ./
    cd build
    ./install
fi
echo 'extension=phalcon.so' > /usr/local/etc/php/conf.d/phalcon.ini


cd /usr/local/src/phalcon-devtools
git checkout tags/v${PHALCON_DEVTOOLS_VERSION} ./
chmod u+x phalcon
if [ -e /usr/bin/phalcon ];then
    unlink /usr/bin/phalcon
fi
ln -s $(pwd)/phalcon /usr/bin/phalcon

pear list | grep -q PHP_CodeSniffer
php_cs_installed=$?
if [ $php_cs_installed -ne 0 ];then
    pear channel-update pear.php.net
    pear install PHP_CodeSniffer
fi
