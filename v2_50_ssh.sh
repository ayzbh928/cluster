#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#����:
#ʹ�ü��:
##############################################################
export PATH
. /etc/init.d/functions


echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m v2_50_ssh start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"

#�趨һЩ�������ܻ���������չ�ı���
net=172.16.3
port=22
file=$HOME/.ssh/id_dsa.pub
user=`whoami`
defaultip="71"

#������Կ��
[ -f ~/.ssh/id_dsa ] && rm -f ~/.ssh/id_dsa*

ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa >/dev/null 2>&1
if [ $? -eq 0 ]
then
    action "create dsa key " /bin/true
else
    action "create dsa key " /bin/false
fi




#����Ҫ,Ҫ�ȼ���Ƿ�װexpect
if [ $(rpm -qa expect|wc -l) -eq 0 ];then
    yum -y install expect
fi

#�ַ���Կ

#####������ļ�����,����Ͳ�����,����Ҳ����Ҫnet������
if [ -z "$1" ];then
    
    read -t 1 -p "Input the ip of the pc(format:1 2 3) :" ip_seg
    echo
    ip_seg=${ip_seg:-$defaultip}
    for i in $ip_seg
    do
        ips="$ips $net.$i"
    done        

else
#���ļ�����ʱ,����ip_exp
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

#��Ҫ�ַ��Ľű���m01��/root�Ƶ�~/scripts/
#���ֻ��m01��Ч
[ ! -d ~/scripts ] && mkdir -p ~/scripts
cp -f ~/basic_setall.sh nfs_set.sh backup_set.sh  mysql_set.sh sersync.sh v2_mod_ssh.sh ip_hostname.txt LNMP_useyum.sh   ~/scripts/


#�ַ��ű�

for ip in $ips
do
    echo
    echo -e "\e[33;40m $ip distribute \e[0m"
    scp -P $port -rp ~/scripts $user@$ip:~
done


runfile=~/scripts/v2_mod_ssh.sh
#�������нű�
for ip in $ips
do
    echo
    echo -e "\e[33;40m $ip run \e[0m"
    ssh -t -p $port $user@$ip "sudo /bin/bash $runfile"
done


########################################
#����Ҫ�õ�=
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