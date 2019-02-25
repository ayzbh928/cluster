#!/bin/bash
##############################################################
#version 0.1 
#hukang 2018 QQ:2859450898 Email:2859450898@qq.com
#作用:对机器进行统一的优化（包括内核优化，字符集，安全设置等）
#使用简介:
##############################################################
export PATH
export LANG=en 

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m basic_setall start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"


#1  关闭selinux,并检查
sed -i 's/SELINUX=enforcing/SELINUX=disabled/'  /etc/selinux/config
grep SELINUX=disabled /etc/selinux/config 

setenforce 0
getenforce


#2 精简开机自启动服务
chkconfig --list | grep 3:on| egrep -v "crond|sshd|network|sysstat|rsyslog" | awk '{print "chkconfig",$1,"off"}' | bash

chkconfig --list | grep 3:on

#3 关闭iptables,两遍比较好
/etc/init.d/iptables  stop
/etc/init.d/iptables  stop

#4 提权oldboy可以sudo
useradd oldboy
\cp /etc/sudoers  /etc/sudoers.ori
echo "oldboy ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
tail -1 /etc/sudoers
visudo -c
echo "123456" | passwd --stdin oldboy

#5.中文字符集
\cp /etc/sysconfig/i18n   /etc/sysconfig/i18n.ori
echo 'LANG="zh_CN.UTF-8"'  >/etc/sysconfig/i18n
source /etc/sysconfig/i18n
echo $LANG

#6.时间同步
echo "#time sync by oldboy at 2019-1-22" >> /var/spool/cron/root
echo '*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null  2>&1'  >>/var/spool/cron/root
crontab -l

###########################################
#正式环境才进行此设置
#7.闲置账号超时时间,命令行安全
#echo 'export  TMOUT=300'  >>/etc/profile
#echo 'export HISTSIZE=5' >>/etc/profile
#echo 'export HISTFILESIZE=5' >>/etc/profile
#tail -3  /etc/profile
#. /etc/profile
###########################################

#8.加大文件描述符,linux默认的不够
echo '*                          -                nofile                    65535'  >>/etc/security/limits.conf
tail -1 /etc/security/limits.conf

#9.内核优化
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
#以下参数是对iptables的优化,防火墙不开会提示,可以忽略
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

#10.修改ssh的配置,其中不允许root登陆暂时注释掉不用
\cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +"%F%H%M%S"`
sed -i 's%#Port 22%Port 52113%'  /etc/ssh/sshd_config
#sed -i 's%#PermitRootLogin yes%PermitRootLogin no%'  /etc/ssh/sshd_config
sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%'   /etc/ssh/sshd_config
sed -i 's%#UseDNS yes%UseDNS no%' /etc/ssh/sshd_config
sed -i 's%GSSAPIAuthentication yes%GSSAPIAuthentication no%'  /etc/ssh/sshd_config
#sed -i '$aAllowUsers root@172.16.3.61\nAllowUsers oldboy@172.16.3.61'  /etc/ssh/sshd_config

egrep "UseDNS|52113|RootLogin|EmptyPass|GSSAPIAuthentication|AllowUsers"   /etc/ssh/sshd_config
#########################################
#没有vpn的时候不要开启这个
#sed -i 's%#ListenAddress 0.0.0.0%ListenAddress 172.16.3.61:52113%' /etc/ssh/sshd_config
#egrep "UseDNS|52113|RootLogin|EmptyPass|GSSAPIAuthentication|ListenAddress"   /etc/ssh/sshd_config
########################################

/etc/init.d/sshd reload

#11.隐藏系统版本
>/etc/issue
>/etc/issue.net 

#12 定时清理邮件服务临时目录的垃圾文件
if [ ! -d /server/scripts ]
then
	mkdir -p /server/scripts
fi

echo "find /var/spool/postfix/maildrop/ -type f|xargs rm -f">/server/scripts/del_file.sh
cat /server/scripts/del_file.sh

echo "00 00 * * * /bin/sh /server/scripts/del_file.sh>/dev/null 2>&1" >>/var/spool/cron/root
crontab -l

#13 锁定关键系统文件,防止被提权篡改
#chattr +i /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/inittab
chattr +i /etc/inittab
mv /usr/bin/{chattr,hukang}

#14 修改/etc/hosts(1,$s/\.1\./\.2\./gc  1,$s/  */ my/gc)

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

# # # #配置yum客户端
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



#14.打补丁
#安装基本软件
yum install  nfs-utils rpcbind  lrzsz  tree vim  -y  
#yum update 或 yum upgrade

#############15一些个性化设置
#安装epel源(内网安装不了了)
#wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo


#修改bash的变量,对所有人生效
cat >>/etc/profile <<EOF

PS1='[\[\e[1;32m\]\u@\[\e[1;31m\]\h,\[\e[0m\]\[\e[34;40m\]\A#\#\[\e[0m\]]\[\e[33;40m\]\w\\$: \[\e[0m\]'
alias lm='ls -al | more'
alias vi='vim'
alias grep='grep --color=auto'

EOF

#修改.vimrc
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

#如果是管理机,还需要将安装的rpm包存起来

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m basic_setall end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo