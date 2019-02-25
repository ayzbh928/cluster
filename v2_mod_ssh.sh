#!/bin/bash
##############################################################
#version 0.2 0.1��ʼ��ֻ��ͨ��ssh����һ̨���������������,�޷����������̨.���������շ���
#����취.�ֶ�Ϊÿ̨�����ָ��IP��ַ,Ȼ��ַ��ű�,�޸������ļ���hostname,���ǲ���������
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#����:
#ʹ�ü��:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m v2_mod_ssh start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"


#########���޸������ļ�################
#���޸Ķ���Ҫ�Ķ��ĵط�(Ϊ�˽ű��ܷ���ʹ��,��ɾ�ټ�)
#��������sed ��ֱ���޸�,��Ϊ���ܸ�����ƥ�䲻��Ҳ���޷��޸�
#�õ�������:��sedƥ�䵽ɾ��,��׷��(���Ƕ��ļ����˽�,sed���ܻ�ƥ��Ȼ��ɾ���ܶණ��)
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

#ȡ���Լ�������ip
myip=`ifconfig eth1 | awk -F "inet addr:|  Bcast:" 'NR==2{print $2}'`

#��ip_host���ձ���ȡ���Լ���ip0,ip1,hostn
fileip=~/scripts/ip_hostname.txt
ip0=`sed -n '/'"\t$myip\t"'/p' $fileip |awk '{print $1}' `
#ip1=`sed -n '/'$myip'/p' $fileip |awk '{print $2}' `
hostn=`sed -n '/'"\t$myip\t"'/p' $fileip |awk '{print $3}' `

#��������ip�޸�����ip
sed -ri '/^IPADDR=/d'  /etc/sysconfig/network-scripts/ifcfg-eth0
echo "IPADDR=$ip0" >>   /etc/sysconfig/network-scripts/ifcfg-eth0

#�������ip��Ϊ��,��ɾ������������
if [ "$ip0" != none ];then
    sed -ri '/^GATEWAY=/d'  /etc/sysconfig/network-scripts/ifcfg-eth1    
fi

#��������ip�޸�hostname
sed -ri '/^HOSTNAME=/d'  /etc/sysconfig/network
echo "HOSTNAME=$hostn" >>   /etc/sysconfig/network
hostname $hostn

#�����

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

