#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#����:ͨ��yum�ķ���һ����װLNMP
#ʹ�ü��:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP use yum start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo
echo -e "\e[32;40m nginx start \e[0m"

#�ƶ�tar.gz��
[ ! -d ~/tools ] && mkdir -p ~/tools
mv ~/scripts/*.tar.gz ~/tools/

#�ж��û�www�Ƿ����
id www >/dev/null
if [ $? -ne 0 ];then
    useradd -u 888 www -s /sbin/nologin -M 
    echo "add user www"
fi


#��װ��
yum install pcre-devel  openssl openssl-devel -y

#��ʼ��װnginx
[ ! -d /app ] && mkdir -p /app
yum install nginx -y

#��ӿ�ݷ�ʽ
ln -s /app/nginx-1.10.2 /app/nginx
ln -s  /app/nginx/sbin/nginx  /usr/bin/nginx 

#��������
#chkconfig nginx on
echo "/app/nginx/sbin/nginx" >>/etc/rc.local

#��鿪������
#chkconfig --list | grep nginx

#����nginx
nginx

#�������
netstat -nultp|grep -v grep| grep nginx 

if [ $? -ne 0 ];then
    echo -e "\e[31;40m nginx error \e[0m"
    exit
fi

##################php##########################
echo
echo -e "\e[32;40m php start \e[0m"


#��װ�ٷ�Դ�Ŀ�
yum install zlib-devel libxml2-devel libjpeg-develevel libjpeg-turbo-devel  libiconv-devel  freetype-devel libpng-devel libcurl-devel libxslt-devel  gd-devel -y

#��װepelԴ
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo

#��װ��ҪepelԴ��3����
yum install libmcrypt-devel mhash mcrypt -y


#����,���벢��װlibiconv
yum install libiconv -y

if [ $? -ne 0 ];then
    echo -e "\e[31;40m libiconv error \e[0m"
    exit 1
fi

#����,���벢��װphp
yum install php -y

if [ $? -ne 0 ];then
    echo -e "\e[31;40m php error \e[0m"
    exit 1
fi

ln -s /app/php5.3.27/ /app/php

#������
[ ! -f /app/php/lib/php.ini ] && cp ~/scripts/php.ini /app/php/lib/
cd /app/php/etc/
cp php-fpm.conf.default php-fpm.conf

#����
/app/php/sbin/php-fpm

#��ӿ�������
echo "/app/php/sbin/php-fpm" >>/etc/rc.local

#����Ƿ�����
lsof -i :9000
ps -ef | grep php-fpm


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LNMP use yum end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo