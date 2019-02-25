#!/bin/bash
##############################################################
#version 0.1 
#hukang 2018 QQ:2859450898 Email:2859450898@qq.com
#����:�Ի�������ͳһ���Ż��������ں��Ż����ַ�������ȫ���õȣ�
#ʹ�ü��:
##############################################################
export PATH
export LANG=en 

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m basic_setall start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"


#1  �ر�selinux,�����
sed -i 's/SELINUX=enforcing/SELINUX=disabled/'  /etc/selinux/config
grep SELINUX=disabled /etc/selinux/config 

setenforce 0
getenforce


#2 ���򿪻�����������
chkconfig --list | grep 3:on| egrep -v "crond|sshd|network|sysstat|rsyslog" | awk '{print "chkconfig",$1,"off"}' | bash

chkconfig --list | grep 3:on

#3 �ر�iptables,����ȽϺ�
/etc/init.d/iptables  stop
/etc/init.d/iptables  stop

#4 ��Ȩoldboy����sudo
useradd oldboy
\cp /etc/sudoers  /etc/sudoers.ori
echo "oldboy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
tail -1 /etc/sudoers
visudo -c
echo "123456" | passwd --stdin oldboy

#5.�����ַ���
\cp /etc/sysconfig/i18n   /etc/sysconfig/i18n.ori
echo 'LANG="zh_CN.UTF-8"'  >/etc/sysconfig/i18n
source /etc/sysconfig/i18n
echo $LANG

#6.ʱ��ͬ��
echo "#time sync by oldboy at 2019-1-22" >> /var/spool/cron/root
echo '*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null  2>&1'  >>/var/spool/cron/root
crontab -l

###########################################
#��ʽ�����Ž��д�����
#7.�����˺ų�ʱʱ��,�����а�ȫ
#echo 'export  TMOUT=300'  >>/etc/profile
#echo 'export HISTSIZE=5' >>/etc/profile
#echo 'export HISTFILESIZE=5' >>/etc/profile
#tail -3  /etc/profile
#. /etc/profile
###########################################

#8.�Ӵ��ļ�������,linuxĬ�ϵĲ���
echo '*                          -                nofile                    65535'  >>/etc/security/limits.conf
tail -1 /etc/security/limits.conf

#9.�ں��Ż�
cat >>/etc/sysctl.conf <<EOF

###add by hukang at $(date +%F)
net.ipv4.tcp_fin_timeout=2
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_keepalive_time=600
net.ipv4.ip_local_port_range=4000  65000
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_max_tw_buckets=36000
net.ipv4.route.gc_timeout=100
net.ipv4.tcp_syn_retries=1
net.ipv4.tcp_synack_retries=1
net.core.somaxconn=16384
net.core.netdev_max_backlog=16384
net.ipv4.tcp_max_orphans=16384
#���²����Ƕ�iptables���Ż�,����ǽ��������ʾ,���Ժ���
net.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_tcp_timeout_established=180
net.netfilter.nf_conntrack_tcp_timeout_time_wait=120
net.netfilter.nf_conntrack_tcp_timeout_close_wait=60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=120
net.core.wmem_default=8388608
net.core.rmem_default=8388608
net.core.rmem_max=16777216
net.core.wmem_max=16777216
###end by hukang at $(date +%F)

EOF
sysctl -p >/dev/null

#10.�޸�ssh������,���в�����root��½��ʱע�͵�����
\cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +"%F%H%M%S"`
sed -i 's%#Port 22%Port 52113%'  /etc/ssh/sshd_config
#sed -i 's%#PermitRootLogin yes%PermitRootLogin no%'  /etc/ssh/sshd_config
sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%'   /etc/ssh/sshd_config
sed -i 's%#UseDNS yes%UseDNS no%' /etc/ssh/sshd_config
sed -i 's%GSSAPIAuthentication yes%GSSAPIAuthentication no%'  /etc/ssh/sshd_config
#sed -i '$aAllowUsers root@172.16.3.61\nAllowUsers oldboy@172.16.3.61'  /etc/ssh/sshd_config

egrep "UseDNS|52113|RootLogin|EmptyPass|GSSAPIAuthentication|AllowUsers"   /etc/ssh/sshd_config
#########################################
#û��vpn��ʱ��Ҫ�������
#sed -i 's%#ListenAddress 0.0.0.0%ListenAddress 172.16.3.61:52113%' /etc/ssh/sshd_config
#egrep "UseDNS|52113|RootLogin|EmptyPass|GSSAPIAuthentication|ListenAddress"   /etc/ssh/sshd_config
########################################

/etc/init.d/sshd reload

#11.����ϵͳ�汾
>/etc/issue
>/etc/issue.net 

#12 ��ʱ�����ʼ�������ʱĿ¼�������ļ�
if [ ! -d /server/scripts ]
then
	mkdir -p /server/scripts
fi

echo "find /var/spool/postfix/maildrop/ -type f|xargs rm -f">/server/scripts/del_file.sh
cat /server/scripts/del_file.sh

echo "00 00 * * * /bin/sh /server/scripts/del_file.sh>/dev/null 2>&1" >>/var/spool/cron/root
crontab -l

#13 �����ؼ�ϵͳ�ļ�,��ֹ����Ȩ�۸�
#chattr +i /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/inittab
chattr +i /etc/inittab
mv /usr/bin/{chattr,hukang}

#14 �޸�/etc/hosts(1,$s/\.1\./\.2\./gc  1,$s/  */ my/gc)

cat >> /etc/hosts <<EOF

172.16.3.5 lb01
172.16.3.6 lb02
172.16.3.8 web01
172.16.3.9 web02
172.16.3.31 nfs01
172.16.3.32 nfs02
172.16.3.41 backup
172.16.3.51 db01 db01.hukang.org
172.16.3.52 db02
172.16.3.61 m01
172.16.3.71 cache

EOF

cat /etc/hosts

# # # #����yum�ͻ���
# # # cd /etc/yum.repos.d
# # # mkdir -p repoback
# # # mv -f CentOS* repoback/

# # # cat > /etc/yum.repos.d/httpd.repo <<EOF

# # # [base]
# # # name=base
# # # baseurl=http://172.16.3.61                                                                             
# # # enabled=1
# # # gpgcheck=0
# # # gpgkey=http://172.16.3.61/RPM-GPG-KEY-CentOS-6

# # # EOF



#14.�򲹶�
#��װ�������
yum install  nfs-utils rpcbind  lrzsz  tree vim  -y  
#yum update �� yum upgrade

#############15һЩ���Ի�����
#��װepelԴ(������װ������)
#wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo


#�޸�bash�ı���,����������Ч
cat >>/etc/profile <<EOF

PS1='[\[\e[1;32m\]\u@\[\e[1;31m\]\h,\[\e[0m\]\[\e[34;40m\]\A#\#\[\e[0m\]]\[\e[33;40m\]\w\\$: \[\e[0m\]'
alias lm='ls -al | more'
alias vi='vim'
alias grep='grep --color=auto'

EOF

#�޸�.vimrc
cat >> ~oldboy/.vimrc <<EOF

set cursorline
set hlsearch
set backspace=2
set ruler
set showmode
set syntax=on
set tabstop=4
set softtabstop=4
set shiftwidth=4
set scrolloff=8
set fileencoding=utf-8

EOF

cat >> /root/.vimrc <<EOF

set cursorline
set hlsearch
set backspace=2
set ruler
set showmode
set syntax=on
set tabstop=4
set softtabstop=4
set shiftwidth=4
set scrolloff=8
set fileencoding=utf-8

EOF

#����ǹ����,����Ҫ����װ��rpm��������

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m basic_setall end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo