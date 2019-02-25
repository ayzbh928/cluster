#!/bin/bash
##############################################################
#version 0.1
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:这个脚本用来在某台已经部署nfs服务的电脑上部署sersync
#使用简介:
##############################################################
export PATH


echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m sersync start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

#把~/scripts/下的tar.gz都移动到~/tools/
[ ! -d ~/tools ] && mkdir -p ~/tools
mv ~/scripts/*.tar.gz ~/tools/

#解压
cd ~/tools/
tar -zxf ./sersync*.tar.gz 
[ ! -d "/usr/local/sersync" ] && mkdir -p /usr/local/sersync/
mv ~/tools/GNU-Linux-x86/* /usr/local/sersync/ && rm -fr ~/tools/GNU-Linux-x86/

#创建软链接
ln -s /usr/local/sersync/sersync2  /usr/bin/sersync

#
read -t 1 -p "Input the dir(Default: /data) you want to monitor: " monidir
monidir=${monidir:-/data}
echo

read -t 1 -p "Input the remote server ip :" serverip
serverip=${serverip:-172.16.3.41}
echo

read -t 1 -p "Input the backup server module :" module
module=${module:-nfsbackup}
echo

users="rsync_backup"
passwordfile="/etc/rsync.password"
path="/usr/local/sersync/rsync_fail_log"

#config conf file
cp /usr/local/sersync/confxml.xml{,.ori}

sed -ri '0,/<localpath watch=/ s#(<localpath watch=).*(>.*)#\1'"$monidir"'\2#1g' /usr/local/sersync/confxml.xml
sed -ri 's#(<remote ip=).*(name=).*(/>)#\1'"$serverip"' \2'"$module"'\3#g' /usr/local/sersync/confxml.xml

sed -ri 's#(<auth start=).*( users=).*( passwordfile=).*(/>)#\1"true"\2'"$users"'\3'"$passwordfile"'\4#g' /usr/local/sersync/confxml.xml

sed -ri 's#(<timeout start=).*( time=.*)#\1"true"\2#g' /usr/local/sersync/confxml.xml

sed -ri 's#(<failLog path=).*( timeToExecute=.*)#\1'"$path"'\2#g' /usr/local/sersync/confxml.xml

#start on boot
echo "/usr/bin/sersync -d -r -o /usr/local/sersync/confxml.xml" >> /etc/rc.local

#start
/usr/bin/sersync -d -r -o /usr/local/sersync/confxml.xml

###############test test test##################
echo -e "\e[32;40m test test test \e[0m"
cd /data/web1_bbs
touch file{01..05}
cd /data/web1_blog
touch file{06..10}
tree /data

ssh -p52113 -f root@172.16.3.41 "tree /nfsbackup"

rm -rf file{01..05}

ssh -p52113 -f root@172.16.3.41 "tree /nfsbackup"

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m sersync end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo