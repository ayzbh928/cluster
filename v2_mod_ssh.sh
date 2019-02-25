#!/bin/bash
##############################################################
#version 0.2 0.1版始终只能通过ssh处理一台虚拟机的网卡重启,无法批量处理多台.所以我最终放弃
#这个办法.手动为每台虚拟机指定IP地址,然后分发脚本,修改网卡文件和hostname,但是不重启网卡
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:
#使用简介:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m v2_mod_ssh start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"


#########先修改网卡文件################
#先修改都需要改动的地方(为了脚本能反复使用,先删再加)
#尽量不用sed 来直接修改,因为可能根本就匹配不到也就无法修改
#好的做法是:先sed匹配到删掉,再追加(若是对文件不了解,sed可能会匹配然后删掉很多东西)
sed -ri '/^ONBOOT=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
echo "ONBOOT=yes" >>   /etc/sysconfig/network-scripts/ifcfg-eth0

sed -ri '/^BOOTPROTO=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
echo "BOOTPROTO=none" >>   /etc/sysconfig/network-scripts/ifcfg-eth0


sed -ri '/^ONBOOT=/d'  /etc/sysconfig/network-scripts/ifcfg-eth1
echo "ONBOOT=yes" >>   /etc/sysconfig/network-scripts/ifcfg-eth1

sed -ri '/^BOOTPROTO=/d'  /etc/sysconfig/network-scripts/ifcfg-eth1
echo "BOOTPROTO=none" >>   /etc/sysconfig/network-scripts/ifcfg-eth1

sed -ri '/^GATEWAY=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
sed -ri '/^DNS1/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
sed -ri '/^DNS2=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
sed -ri '/^######################/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
cat >>/etc/sysconfig/network-scripts/ifcfg-eth0<<EOF
######################
GATEWAY=10.0.0.2
DNS1=10.0.0.2
DNS2=223.5.5.5
######################
EOF

#取得自己的内网ip
myip=`ifconfig eth1 | awk -F "inet addr:|  Bcast:" 'NR==2{print $2}'`

#从ip_host对照表中取出自己的ip0,ip1,hostn
fileip=~/scripts/ip_hostname.txt
ip0=`sed -n '/'"\t$myip\t"'/p' $fileip |awk '{print $1}' `
#ip1=`sed -n '/'$myip'/p' $fileip |awk '{print $2}' `
hostn=`sed -n '/'"\t$myip\t"'/p' $fileip |awk '{print $3}' `

#根据内网ip修改外网ip
sed -ri '/^IPADDR=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=$ip0" >>   /etc/sysconfig/network-scripts/ifcfg-eth0

#如果外网ip不为空,就删掉内网的网关
if [ "$ip0" != none ];then
    sed -ri '/^GATEWAY=/d'  /etc/sysconfig/network-scripts/ifcfg-eth1    
fi

#根据内网ip修改hostname
sed -ri '/^HOSTNAME=/d'  /etc/sysconfig/network
echo "HOSTNAME=$hostn" >>   /etc/sysconfig/network
hostname $hostn

#检查结果

echo -e "\e[31;40m########################################  \e[0m"
echo -e "\e[33;40m eth0 \e[0m"
grep -E 'HWADDR|UUID|ONBOOT|IPADDR|GATEWAY|DNS1|DNS2|BOOTPROTO'  /etc/sysconfig/network-scripts/ifcfg-eth0
echo -e "\e[33;40m eth1 \e[0m"
grep -E 'HWADDR|UUID|ONBOOT|IPADDR|GATEWAY|DNS1|DNS2|BOOTPROTO'  /etc/sysconfig/network-scripts/ifcfg-eth1
echo -e "\e[33;40m hostname \e[0m"
grep HOSTNAME   /etc/sysconfig/network
echo -e "\e[31;40m########################################  \e[0m"
##############################################################

sh ~/scripts/basic_setall.sh > /root/basic_setall.log

case $hostn in 
backup)
    sh ~/scripts/backup_set.sh
    ;;
nfs01|nfs02)
    sh ~/scripts/v2_nfs_set.sh
    sh ~/scripts/backup_client.sh &&\
    sh ~/scripts/sersync.sh
    ;;
db01|db02)
    sh ~/scripts/mysql_set.sh
    ;;
web01|web03)
    sh ~/scripts/LNMP_useyum.sh &&\
    sh ~/scripts/nfs_client.sh
    sh ~/scripts/backup_client.sh
    ;;
web02)
    sh ~/scripts/
    sh ~/scripts/nfs_client.sh
    sh ~/scripts/backup_client.sh    
    ;;
lb01|lb02)
    sh ~/scripts/keep_lb_set.sh
mem)
	;;
esac

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m  v2_mod_ssh end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo

