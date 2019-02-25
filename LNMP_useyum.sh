#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:通过yum的方法一键安装LNMP
#使用简介:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP use yum start \e[0m"
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
yum install nginx -y

#添加快捷方式
ln -s /app/nginx-1.10.2 /app/nginx
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
yum install libiconv -y

if [ $? -ne 0 ];then
    echo -e "\e[31;40m libiconv error \e[0m"
    exit 1
fi

#配置,编译并安装php
yum install php -y

if [ $? -ne 0 ];then
    echo -e "\e[31;40m php error \e[0m"
    exit 1
fi

ln -s /app/php5.3.27/ /app/php

#简单配置
[ ! -f /app/php/lib/php.ini ] && cp ~/scripts/php.ini /app/php/lib/
cd /app/php/etc/
cp php-fpm.conf.default php-fpm.conf

#启动
/app/php/sbin/php-fpm

#添加开机启动
echo "/app/php/sbin/php-fpm" >>/etc/rc.local

#检查是否启动
lsof -i :9000
ps -ef | grep php-fpm


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP use yum end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo