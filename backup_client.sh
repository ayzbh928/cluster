#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:
#使用简介: 部署在任何需要向备份服务器推送备份的机器上.
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m backup_client start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

read -t 1 -p "Input authuser(just a string,Default is rsync_backup): " authuser
authuser=${authuser:-rsync_backup}
echo

read -t 1 -p "Input the password of authuser(Default is oldboy): " passwd
passwd=${passwd:-oldboy}
echo

read -t 1 -p "Input the password file(Default /etc/rsync.password): " passwdfile
passwdfile=${passwdfile:-/etc/rsync.password}
echo

#这里只部署rsync的客户端,不考虑实时备份,所以不创建其他目录
read -t 1 -p "Input the backup path1(Default /backup/): " backpath1
backpath1=${backpath1:-/backup/}
echo

#install rsync
/usr/bin/yum -y install rsync


#create passwdfile
echo "$passwd">$passwdfile
/bin/chmod 600 $passwdfile


#create backuppath
mkdir -p $backpath1


#显示一些结果,以表明部署过程没有error
echo -e "\e[32;40m check results  \e[0m"
ls -ld $backpath1
ls -l $passwdfile
cat /etc/rsync.password


###########测试########################
echo -e "\e[32;40m test test test \e[0m"
cd $backpath1
mkdir -p dir{01..05}
touch file{01..05}

serverip=172.16.3.41
rsync -avz $backpath1 $authuser@$serverip::backup/ --password-file=$passwdfile


#生成密钥对
[ -f ~/.ssh/id_dsa ] && rm -f ~/.ssh/id_dsa*
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa >/dev/null 2>&1
ssh-copy-id -i ~/.ssh/id_dsa.pub "-p 52113 root@172.16.3.41"

ssh -p52113 -f root@172.16.3.41 "ls -l /backup"


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m backup_client end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo