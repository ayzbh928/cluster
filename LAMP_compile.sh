#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#����:ͨ������ķ���һ����װLAMP(�ٶ�Ҫ��װ��������Ѿ��ͽű���ͬһĿ¼~/scripts/��)
#ʹ�ü��:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LAMP start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo
echo -e "\e[32;40m apache start \e[0m"


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
yum install zlib-devel pcre-devel expat-devel -y


#��ʼ��װ
cd ~/tools/
tar zxf apr-1.6.3.tar.gz
cd apr-1.6.3
./configure --prefix=/usr/local/apr &&\
make && make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m apr error \e[0m"
    exit 1
fi

cd ~/tools/
tar zxf apr-iconv-1.2.2.tar.gz
cd apr-iconv-1.2.2
./configure --prefix=/usr/local/apr-iconv --with-apr=/usr/local/apr &&\
make && make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m apr-iconv error \e[0m"
    exit 1
fi

cd ~/tools/
tar zxf apr-util-1.6.1.tar.gz
cd apr-util-1.6.1
./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr --with-apr-iconv=/usr/local/apr-iconv/bin/apriconv &&\
make && make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m apr-util error \e[0m"
    exit 1
fi

[ ! -d /app ] && mkdir -p /app
cd ~/tools/
tar zxf httpd*.tar.gz &&\
httpdversion=`ls -ld  httpd*|awk '/^d/{print $NF}'`
cd $httpdversion

./configure \
--prefix=/app/$httpdversion \
--enable-expires \
--enable-headers \
--enable-modules=most \
--enable-so \
--with-apr=/usr/local/apr \
--with-apr-util=/usr/local/apr-util \
--with-mpm=worker \
--enable-deflate \
--enable-rewrite &&\
make && make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m apache error \e[0m"
    exit 1
fi

#һЩ��������
cp  /app/$httpdversion/apache/bin/apachectl  /etc/init.d/httpd
ln -s /app/$httpdversion /app/apache
ln -s /app/$httpdversion/apache/bin/apachectl /usr/bin/apache

#��������,��֧��chkconfig --add
echo "/app/$httpdversion/apache/bin/apachectl" >>/etc/rc.local

#################php########################
echo
echo -e "\e[32;40m php start \e[0m"

#��װ��
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum install zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel libxslt-devel libmcrypt-devel mhash mhash-devel mcrypt openssl-devel -y



#����,���벢��װlibiconv
cd ~/tools/
tar zxf libiconv*.tar.gz  &&\
cd libiconv*/ &&\
./configure --prefix=/usr/local/libiconv &&\
make &&make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m libiconv error \e[0m"
    exit 1
fi

#����,���벢��װphp
cd ~/tools/
tar zxf php*.tar.gz &&\
cd php*/

./configure \
--prefix=/app/php5.3.27 \
--with-apxs2=/app/apache/bin/apxs \
--with-mysql=mysqlnd \
--with-iconv-dir=/usr/local/libiconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-safe-mode \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--with-curlwrappers \
--enable-mbregex \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--enable-short-tags \
--enable-zend-multibyte \
--enable-static \
--with-xsl \
--enable-ftp &&\
make &&make install

if [ $? -ne 0 ];then
    echo -e "\e[31;40m php error \e[0m"
    exit 1
fi

ln -s /app/php5.3.27/ /app/php


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m LAMP end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo














