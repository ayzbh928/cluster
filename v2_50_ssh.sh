#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用:
#使用简介:
##############################################################
export PATH
. /etc/init.d/functions


echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m v2_50_ssh start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

#设定一些将来可能会在这里扩展的变量
net=172.16.3
port=22
file=$HOME/.ssh/id_dsa.pub
user=`whoami`
defaultip="71"

#生成密钥对
[ -f ~/.ssh/id_dsa ] && rm -f ~/.ssh/id_dsa*

ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa >/dev/null 2>&1
if [ $? -eq 0 ]
then
    action "create dsa key " /bin/true
else
    action "create dsa key " /bin/false
fi




#很重要,要先检测是否安装expect
if [ $(rpm -qa expect|wc -l) -eq 0 ];then
    yum -y install expect
fi

#分发公钥

#####如果从文件读入,这里就不用了,而且也不需要net参数了
if [ -z "$1" ];then
    
    read -t 1 -p "Input the ip of the pc(format:1 2 3) :" ip_seg
    echo
    ip_seg=${ip_seg:-$defaultip}
    for i in $ip_seg
    do
        ips="$ips $net.$i"
    done        

else
#从文件读入时,才有ip_exp
    ip0=(`awk '{print $1}' $1 `)
    ip1=(`awk '{print $2}' $1`)
    hostn=(`awk '{print $3}' $1 `)
    ip_a=(`awk '{print $4}' $1 |sed '/^$/d'`)
    ips=`awk '{print $4}' $1 |sed '/^$/d'`
    sum=`echo "$ip_a" |wc -l`
fi


for ip in $ips
do
    expect expect-copy-sshkey.exp $file $ip $port $user &>/dev/null
    if [ $? -eq 0 ];then
        action "$ip distribute " /bin/true
    else
        action "$ip distribute " /bin/false
    fi
done

#将要分发的脚本从m01的/root移到~/scripts/
#这句只对m01有效
[ ! -d ~/scripts ] && mkdir -p ~/scripts
cp -f ~/basic_setall.sh nfs_set.sh backup_set.sh  mysql_set.sh sersync.sh v2_mod_ssh.sh ip_hostname.txt LNMP_useyum.sh   ~/scripts/


#分发脚本

for ip in $ips
do
    echo
    echo -e "\e[33;40m $ip distribute \e[0m"
    scp -P $port -rp ~/scripts $user@$ip:~
done


runfile=~/scripts/v2_mod_ssh.sh
#批量运行脚本
for ip in $ips
do
    echo
    echo -e "\e[33;40m $ip run \e[0m"
    ssh -t -p $port $user@$ip "sudo /bin/bash $runfile"
done


########################################
#这里要拿掉=
#for((i=0; i<$sum; i++))
#do
#    ssh -t -p $port $user@${ips[$i]} "sudo /bin/bash $runfile ${ip0[$i]} ${ip1[$i]} ${hostn[$i]} "
#    ssh -f -p $user@${ips[$i]} "sudo /etc/init.d/network restart"

#    sleep 2s
#    echo -e "\e[32;40m########################################  \e[0m"
#    echo -e "\e[31;40m ${ips[$i]} finished \e[0m"
#    echo -e "\e[32;40m########################################  \e[0m"
#done
#########################################

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m v2_50_ssh end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo