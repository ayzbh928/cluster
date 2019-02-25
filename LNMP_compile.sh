#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:通过编译的方法一键安装LNMP(假定要安装的软件都已经和脚本在同一目录~/scripts/下)
#使用简介:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo
echo -e "\e[32;40m nginx start \e[0m"

#移动tar.gz包
[ ! -d ~/tools ] && mkdir -p ~/tools
mv ~/scripts/*.tar.gz ~/tools/

#判断用户www是否存在
id www >/dev/null
if [ $? -ne 0 ];then
    useradd -u 888 www -s /sbin/nologin -M 
    echo "add user www"
fi


#安装库
yum install pcre-devel  openssl openssl-devel -y

#开始安装nginx
[ ! -d /app ] && mkdir -p /app
cd ~/tools/
tar zxf ~/tools/nginx*.tar.gz &&\

nginxversion=`ls -ld  nginx*|awk '/^d/{print $NF}'`
cd $nginxversion
./configure --user=www --group=www --with-http_ssl_module --with-http_stub_status_module --prefix=/app/$nginxversion &&\
make && make install &&\

#添加快捷方式
ln -s /app/$nginxversion /app/nginx
ln -s  /app/nginx/sbin/nginx  /usr/bin/nginx 

#开机启动
#chkconfig nginx on
echo "/app/nginx/sbin/nginx" >>/etc/rc.local

#检查开机启动
#chkconfig --list | grep nginx

#启动nginx
nginx

#检查启动
netstat -nultp|grep -v grep| grep nginx 

if [ $? -ne 0 ];then
    echo -e "\e[31;40m nginx error \e[0m"
    exit
fi

##################php##########################
echo
echo -e "\e[32;40m php start \e[0m"


#安装官方源的库
yum install zlib-devel libxml2-devel libjpeg-develevel libjpeg-turbo-devel  libiconv-devel  freetype-devel libpng-devel libcurl-devel libxslt-devel  gd-devel -y

#安装epel源
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo

#安装需要epel源的3个库
yum install libmcrypt-devel mhash mcrypt -y


#配置,编译并安装libiconv
cd ~/tools/
tar zxf libiconv*.tar.gz  &&\
cd libicon*/ &&\
./configure --prefix=/usr/local/libiconv &&\
make &&make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m libiconv error \e[0m"
    exit 1
fi

#配置,编译并安装php
cd ~/tools/
tar zxf php*.tar.gz &&\
cd php*/

./configure   --prefix=/app/php5.3.27 --enable-mysqlnd --with-mysql=mysqlnd  --with-iconv-dir=/usr/local/libiconv --with-freetype-dir  --with-jpeg-dir  --with-png-dir  --with-zlib  --with-libxml-dir=/usr  --enable-xml  --disable-rpath  --enable-safe-mode  --enable-bcmath  --enable-shmop  --enable-sysvsem  --enable-inline-optimization  --with-curl  --with-curlwrappers  --enable-mbregex  --enable-fpm  --enable-mbstring  --with-mcrypt  --with-gd  --enable-gd-native-ttf  --with-openssl  --with-mhash  --enable-pcntl  --enable-sockets  --with-xmlrpc  --enable-zip  --enable-soap  --enable-short-tags  --enable-zend-multibyte  --enable-static  --with-xsl  --with-fpm-user=www  --with-fpm-group=www --enable-ftp  &&\
make && make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m php error \e[0m"
    exit 1
fi

ln -s /app/php5.3.27/ /app/php





echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo