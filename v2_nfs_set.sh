#!/bin/bash
##############################################################
#version 0.2
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#����:��ĳ̨�����ϲ���nfs����,���������Ŀ¼,�еĿ�д,�е�ֻ��
#ʹ�ü��:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m NFS begin \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

clientaddr=172.16.3.0/24

#���ﲻ��"",�ᵼ�����ƴ����ʱ,����( ),nfs�����ļ��﷨�����
wshare="web1_bbs web1_blog"

woptions="(rw,sync,all_squash,anonuid=888,anongid=888)"

#ro,����r
rshare="web1_read web2_read"
roptions="(ro,sync,all_squash,anonuid=888,anongid=888)"


#install
yum -y install nfs-utils rpcbind

#config nfs
>/etc/exports
echo "">>/etc/exports
echo "#add by hukang at $(date +%F) ">>/etc/exports
echo -e "#\e[32;40mthese dirs can be rw \e[0m" >>/etc/exports

for wdir in $wshare
do
    echo "/data/$wdir $clientaddr$woptions">>/etc/exports
done

echo "">>/etc/exports
echo -e "#\e[32;40mthese dirs can be ro \e[0m" >>/etc/exports
for rdir in $rshare 
do
    echo "/data/$rdir $clientaddr$roptions">>/etc/exports
done


#�ں��Ż�
cat  >> /etc/sysctl.conf <<EOF



net.core.wmem_default=8388608
net.core.rmem_default=8388608
net.core.rmem_max=16777216
net.core.wmem_max=16777216



EOF
sysctl -p>/dev/null 2>&1

#�ж�www�Ƿ����,û�о�����û�www
grep www /etc/passwd >/dev/null
if [ $? -eq 1 ];then
    useradd -u 888 www -s /sbin/nologin -M
fi

#�����ļ���
username=`grep www /etc/passwd |awk -F ":" '{print $1}'`

for wdir in $wshare
do
    [ ! -d "/data/$wdir" ] && mkdir -p /data/$wdir
    chown -R $username:$username /data/$wdir
done

for rdir in $rshare
do
    [ ! -d "/data/$rdir" ] && mkdir -p /data/$rdir
    chown -R $username:$username /data/$rdir
done


#start on boot
chkconfig nfs on
chkconfig rpcbind on


#start rpc,then nfs
/etc/init.d/rpcbind start &&\
/etc/init.d/nfs start


#��ʾһЩ���
echo -e "\e[33;40m###########check results################  \e[0m"
myip=`ifconfig eth1|awk -F '[ :]+' 'NR==2{print $4}'`
showmount -e $myip
cat /etc/exports
for wdir in $wshare
do
    ls -ld /data/$wdir
done

for rdir in $rshare
do
    ls -ld /data/$rdir
done


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m NFS end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo
