#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:在某台主机上部署nfs服务,共享2个目录,一个可写/data/w_shared,一个可读/data/r_shared
#使用简介:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m NFS begin \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

clientaddr=172.16.3.0/24

#这里不加"",会导致最后拼起来时,少了( ),nfs配置文件语法出错的
wshare=/data/w_shared
woptions="(rw,sync,all_squash,anonuid=65534,anongid=65534)"

#ro,不是r
rshare=/data/r_shared
roptions="(ro,sync,all_squash,anonuid=65534,anongid=65534)"


#install
yum -y install nfs-utils rpcbind

#config nfs
cat >>/etc/exports <<EOF



#add by hukang at 2019/01/27
$wshare $clientaddr$woptions
$rshare $clientaddr$roptions



EOF

#内核优化
cat  >> /etc/sysctl.conf <<EOF



net.core.wmem_default=8388608
net.core.rmem_default=8388608
net.core.rmem_max=16777216
net.core.wmem_max=16777216



EOF
sysctl -p>/dev/null

#判断www是否存在,没有就添加用户www
grep www /etc/passwd >/dev/null
if [ $? -eq 1 ];then
    useradd -u 888 www -s /sbin/nologin -M
fi

#建立文件夹
#这样为空,username=`grep 65534 /etc/passwd >/dev/null`
username=`grep www /etc/passwd |awk -F ":" '{print $1}'`

[ ! -d "$wshare" ] && mkdir -p $wshare
chown -R $username:$username $wshare

[ ! -d "$rshare" ] && mkdir -p $rshare
chown -R $username:$username $rshare


#start on boot
chkconfig nfs on
chkconfig rpcbind on



#start rpc,then nfs
/etc/init.d/rpcbind start &&\
/etc/init.d/nfs start


#显示一些结果
echo -e "\e[33;40m########################################  \e[0m"
myip=`ifconfig eth1|awk -F '[ :]+' 'NR==2{print $4}'`
showmount -e $myip
cat /etc/exports
ls -ld $wshare $rshare


echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m NFS end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo
