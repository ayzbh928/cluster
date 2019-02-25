#!/bin/bash
##############################################################
#version 0.1 
#hukang 2019/2/4 QQ:2859450898 Email:2859450898@qq.com
#作用: 一键在两台机器上部署mysql+heartbeat+drbd双主互为主从方案
#使用简介:
##############################################################
export PATH

echo
echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m mysql+heartbeat+drbd start \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo 
echo -e "\e[1;31mMake sure hostname is correct  \e[0m"

hname1="data-1-1"
hname2="data-1-2"
ip1_eth0=10.0.0.91
ip1_eth1=10.0.10.91
ip1_vip=10.0.0.191

ip2_eht0=10.0.0.92
ip2_eth1=10.0.10.92
ip2_vip=10.0.0.192

RETVAL=0
#1  关闭selinux,并检查
sed -i 's/SELINUX=enforcing/SELINUX=disabled/'  /etc/selinux/config
grep SELINUX=disabled /etc/selinux/config 

setenforce 0
getenforce
#3 关闭iptables,两遍比较好
/etc/init.d/iptables  stop
/etc/init.d/iptables  stop


#取得主机名,主机名应该事先配好
hostn="`hostname`"


#修改hosts
/bin/cp /etc/hosts{,.ori}
sed -i '/^10.0.0/d' /etc/hosts
cat >/etc/hosts<<EOF
${ip1_eth1} ${hname1}                                                  
${ip2_eth1} ${hname2}  

EOF

#添加路由
if [ "$hostn" == "$hname1" ];then
	ip_eth1=$ip2_eth1
else
	ip_eth1=$ip1_eth1
fi

/sbin/route add -host $ip_eth1 dev eth1
echo "/sbin/route add -host $ip_eth1 dev eth1" >>/etc/rc.local

# # # #添加dns,如果需要yum安装
# # # cat >>/etc/sysconfig/network-scripts/ifcfg-eth0<<EOF
# # # DNS1=10.0.0.2                               
# # # DNS2=223.5.5.5
# # # EOF

#把~/scripts/下的tar.gz都移动到~/tools/
[ ! -d ~/tools ] && mkdir -p ~/tools
mv ~/scripts/*.tar.gz ~/tools/
mv ~/scripts/*.rpm ~/tools/
mv ~/scripts/*.zip ~/tools/



# # # # #编译安装drbd
# # # # cd ~/tools
# # # # tar xf drbd-8.4.4.tar.gz
# # # # cd drbd-8.4.4
 # # # # ./configure --prefix=/app/drbd-8.4.4 --with-km --with-heartbeat --sysconfdir=/etc/  &&\
# # # # make KDIR=/usr/src/kernels/$(uname -r)/ >/dev/null &&\
# # # # make install >/dev/null

modprobe drbd
echo "modprobe drbd" >>/etc/rc.local
chkconfig --add drbd
#chkconfig drbd on

#分区
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary 0% 40%
parted -s /dev/sdb mkpart primary 40% 75%
parted -s /dev/sdb mkpart primary 75% 100%
partprobe
parted /dev/sdb p
parted /dev/sdb align-check optimal 1
parted /dev/sdb align-check optimal 2
parted /dev/sdb align-check optimal 3

#格式化
if [ "$hostn" == "$hname1" ];then
	mkfs.ext4 /dev/sdb1 
	tune2fs -c -1 /dev/sdb1
else
	mkfs.ext4 /dev/sdb2
	tune2fs -c -1 /dev/sdb2
fi

#配置文件
[ -f /etc/drbd.conf ]&& /bin/cp /etc/drbd.conf /etc/drbd.conf_$(date +%F)
/bin/cp ~/scripts/drbd.conf /etc

sed -i 's#10.0.10.7#'${ip1_eth1}'#g' /etc/drbd.conf
sed -i 's#10.0.10.8#'${ip2_eth1}'#g' /etc/drbd.conf

drbdadm create-md data3306
drbdadm create-md data3307
drbdadm up data3306
drbdadm up data3307

read -p "Pls run this script on another pc..." nouse
sleep 10

if [ "$hostn" == "$hname1" ];then
	drbdadm -- --overwrite-data-of-peer primary data3306
else
	drbdadm -- --overwrite-data-of-peer primary data3307
fi

[ ! -d /data3306 ]&& mkdir /data3306
[ ! -d /data3307 ]&& mkdir /data3307

if [ "$hostn" == "$hname1" ];then
	mount /dev/drbd0 /data3306
	RETVAL=$?
else
	mount /dev/drbd1 /data3307
	RETVAL=$?
fi

# # # # if [ "$RETVAL" -ne 0 ];then
	# # # # echo "some mistake happened...exit"
	# # # # exit 1
# # # # fi
########################################################
echo
echo -e "\e[32;40m mysql \e[0m"

#判断用户mysql是否存在
id mysql >/dev/null
if [ $? -ne 0 ];then
    useradd mysql -s /sbin/nologin -M 
	echo -e "\e[35;40madd user mysql \e[0m"
fi

cd ~/tools/
unzip data.zip
if [ "$hostn" == "$hname1" ];then
	/bin/cp data/3306/{my.cnf,mysql,mysql_oldboy3306.err} /data3306
else
	/bin/cp data/3307/{my.cnf,mysql,mysql_oldboy3307.err} /data3307
fi

# # # # #解压
# # # # cd ~/tools/
# # # # tar zxf mysql*.tar.gz  &&\
# # # # sqlversion=`ls -ld  mysql*|awk '/^d/{print $NF}'`
# # # # sql=`echo "$sqlversion" |awk -F '-' '{print $1$2}'`

#整个文件夹移到/app下并改个短名
[ ! -d /app ] && mkdir -p /app
mv $sqlversion /app/$sql

#soft link
cd /app
ln -s $sql mysql

################一些设置####################
cd mysql

mkdir -p /app/mysql/data
chown -R mysql.mysql /app/mysql

#修改文件中mysql的位置信息
sed -i 's#/usr/local/mysql#/app/mysql#g' /app/mysql/bin/mysqld_safe

echo 'export PATH=/app/mysql/bin:$PATH' >>/etc/profile

##
if [ "$hostn" == "$hname1" ];then
	port=3306
else
	port=3307
fi

/app/mysql/scripts/mysql_install_db --basedir=/app/mysql --datadir=/data${port}/data --user=mysql
chown -R mysql.mysql /data${port}
chmod +x /data${port}/mysql

/data${port}/mysql start
ss -nultp|grep $port
sleep 5
#优化数据库
MYSQL_PATH=/app/mysql/bin
myuser=root
mypass="123"
mysock=/data${port}/mysql.sock
MYSQL_CMD="$MYSQL_PATH/mysql -u$myuser -p$mypass -S $mysock"

$MYSQL_PATH/mysqladmin -u$myuser password "$mypass" -S $mysock
#一些安全设置
$MYSQL_CMD -e "drop database test;"
$MYSQL_CMD -e "drop user ''@localhost;"
$MYSQL_CMD -e "drop user ''@'`hostname`';"
$MYSQL_CMD -e "drop user 'root'@'`hostname`';"
$MYSQL_CMD -e "drop user 'root'@'::1';"

$MYSQL_CMD -e "flush privileges;"

#检查一下
$MYSQL_CMD -e "show databases;"
$MYSQL_CMD -e "select user,host from mysql.user;"


########################################################
echo
echo -e "\e[32;40m heartbeat \e[0m"

cd ~/tools
rpm -ivh epel-release-6-8.noarch.rpm
yum install heartbeat* -y


/bin/cp /etc/ha.d/ha.cf /etc/ha.d/ha.cf_$(date +%F)
/bin/cp /etc/ha.d/haresources /etc/ha.d/haresources_$(date +%F)
/bin/cp /etc/ha.d/authkeys  /etc/ha.d/authkeys_$(date +%F)

cat >/etc/ha.d/ha.cf<<EOF
debugfile /var/log/ha-debug
logfile /var/log/ha-log
logfacility     local0
keepalive 2
deadtime 30
warntime 10
initdead 120
mcast eth1 225.0.0.1 694 1 0
auto_failback on
node    $hname1
node    $hname2
EOF

cat >/etc/ha.d/authkeys<<EOF
auth 1
1 sha1 4d5c01842f37d90651f9693783c6564279fed6f4
EOF
###必须
chmod 600 /etc/ha.d/authkeys

cat >/etc/ha.d/haresources<<EOF
$hname1 IPaddr::${ip1_vip}/24/eth0 drbddisk::data3306 Filesystem::/dev/drbd0::/data3306::ext4 mysqld3306
$hname2 IPaddr::${ip2_vip}/24/eth0 drbddisk::data3307 Filesystem::/dev/drbd1::/data3307::ext4 mysqld3307
EOF

#大坑在此
#/bin/cp /data${port}/mysql /etc/ha.d/resource.d/mysqld
/bin/cp ~/tools/data/3306/mysql /etc/ha.d/resource.d/mysqld3306
/bin/cp ~/tools/data/3307/mysql /etc/ha.d/resource.d/mysqld3307
chmod +x /etc/ha.d/resource.d/mysqld3306
chmod +x /etc/ha.d/resource.d/mysqld3307

/etc/init.d/heartbeat start

chkconfig heartbeat on

#测试
ip add |grep 10.0.0
cat /proc/drbd
df -hT
ss -nultp|grep 330


/usr/share/heartbeat/hb_standby
/usr/share/heartbeat/hb_takeover

echo -e "\e[33;40m########################################  \e[0m"
echo -e "\e[33;40m mysql+heartbeat+drbd end \e[0m"
echo -e "\e[33;40m########################################  \e[0m"
echo