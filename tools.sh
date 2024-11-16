#!/bin/bash
# 初始化配置jenkins
init_jenkins() {
# 定义路径变量
# install_path=/usr/local
tomcat_path=/usr/local/tomcat
# 下载jdk
wget ftp://10.8.154.178/pub/jenkins/jdk-11.0.2_linux-x64_bin.tar.gz
tar xzf jdk-11.0.2_linux-x64_bin.tar.gz -C /usr/local
mv /usr/local/jdk-11.0.2 /usr/local/java
# 配置java环境变量
echo 'PATH=$PATH:/usr/local/java/bin' >> /etc/profile
# 下载tomcat
echo "下载tomcat中..."
sleep 2
wget https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.98/bin/apache-tomcat-8.5.98.tar.gz --no-check-certificate
tar xf apache-tomcat-8.5.98.tar.gz -C /usr/local
mv /usr/local/apache-tomcat-8.5.98 /usr/local/tomcat
# 下载maven
echo "下载maven中..."
sleep 2
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz --no-check-certificate
tar xf apache-maven-3.8.8-bin.tar.gz -C /usr/local
mv /usr/local/apache-maven-3.8.8 /usr/local/maven
# 下载jenkins.war包
wget https://get.jenkins.io/war-stable/2.414.1/jenkins.war --no-check-certificate
# 将jenkins.war包移动到tomcat的默认发布目录进行部署
rm -rf /usr/local/tomcat/webapps/*
cp -r jenkins.war $tomcat_path/webapps/
# 启动tomcat
sed -i '2i\source /etc/profile' $tomcat_path/bin/startup.sh
nohup $tomcat_path/bin/startup.sh &
}

#################
# 安装下载 mysql 
# 并修改密码为 1
#################
install_mysql() {
	read -p "此脚本将安装5.7版本的mysql,你是否安装(y/n): " choose
	if [ $choose == "n" ];then
		echo "退出安装mysql~~~"
		return
	fi

        echo "你选择了继续安装,请耐性等待..."
	yum -y remove `rpm -qa | grep mysql`
	rm -rf /etc/yum.repos.d/mysql*
	rm -rf /etc/my*
	rm -rf /var/log/mysql*
        echo "下载wget中..."
        yum -y install wget
        wget https://dev.mysql.com/get/mysql80-community-release-el7-11.noarch.rpm -O /opt/mysql80-community-release-el7-11.noarch.rpm
        rpm -ivh /opt/mysql80-community-release-el7-11.noarch.rpm
	# 关闭 gpgcheck 检测
	sed -i "/gpgcheck/c\gpgcheck=0" /etc/yum.repos.d/mysql-community.repo
        yum -y install yum-utils &> /dev/null && echo "yum-utils 工具安装完成*_* yes"
        yum-config-manager --disable mysql80-community &> /dev/null
        yum-config-manager --enable mysql57-community &> /dev/null
        yum -y install mysql-community-server
        clear
        echo -e "\e[42;37m 安装 mysql 成功 \e[0m"
#       echo "请启动 mysql 服务,然后查看 /var/log/mysqld.log 文件获取密码"
        systemctl start mysqld
        a=$(cat /etc/my.cnf | wc -l)
        sed -ri "${a}i\character_set_server=utf8\nvalidate_password=off" /etc/my.cnf
        systemctl restart mysqld
#       echo -e "\e[41;37m 初始化密码如下,请注意修改密码 \e[0m"
       	# 初始化密码
	passwd0=$(grep "password" /var/log/mysqld.log | awk -F ": " '{print $2}')
        # 修改密码
	read -p "请输入一个新密码,用来登录 mysql: " newpwd
	mysqladmin -uroot -p"$passwd0" password $newpwd
        echo "已将将您的密码改为 $newpwd ,您可以直接登录~"
}

# 下载安装 gitlab
install_gitlab() {
gitlab_path=/etc/gitlab/gitlab.rb
clear
read -p "gitlab下载花费时间较长,大概需要30分钟,请留有足够的时间下载(y/n): " choose
if [ $choose == "n" ];then
	return 0
fi
# 配置 gitlab 的yum仓库
echo '[gitlab-ce]
name=Gitlab CE Repository
baseurl=https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el$releasever
gpgcheck=0
enabled=1' > /etc/yum.repos.d/gitlab.repo
echo "配置gitlab的yum仓库完毕,准备下载..."
sleep 2
# 安装gitlab服务
 yum -y install gitlab-ce
# 修改 /etc/gitlab/gitlab.rb 配置文件
clear
echo "安装完成,正在修改配置文件中,请配合操作!"
read -p "请输入您的ip地址: " ip
sed -i "s#external_url 'http://gitlab.example.com'#external_url \'http://$ip\'#" $gitlab_path
sed -i "/time_zone/c\gitlab_rails['time_zone'] = 'Asia/Shanghai'" $gitlab_path
sed -i "/# git_data_dirs({/c\ git_data_dirs({" $gitlab_path
sed -i "/#   \"default\" => {/c\ \"default\" => {" $gitlab_path
sed -i "/#     \"path\" => \"\/mnt\/nfs-01\/git-data\"/c\ \"path\" => \"/mnt/nfs-01/git-data\"" $gitlab_path
sed -i "/#    }/c\     }" $gitlab_path
sed -i "/# })/c\  })" $gitlab_path
sed -i "/gitlab_shell_ssh_port/c\ gitlab_rails['gitlab_shell_ssh_port'] = 22" $gitlab_path
gitlab-ctl reconfigure
pkill -9 nginx &> /dev/null
pkill -9 httpd &> /dev/null
clear
echo "正在启动gitlab服务中..."
sleep 2
gitlab-ctl start
echo "初始化密码: "
grep "Password:" /etc/gitlab/initial_root_password
}
# install_gitlab
# 测试脚本情况
# init_jenkins
install_zabbix() {
read -p "本次安装的是zabbix5.0版本,您确认安装吗 (y/n) : " choose
if [ $choose == "n" ];then
	echo "您已取消安装"
	sleep 2
	return
fi
# 配置yum源仓库
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
# sed -i 's#http://repo.zabbix.com#https://mirrors.aliyun.com/zabbix#' /etc/yum.repos.d/zabbix.repo
sleep 2
sed -i "/gpgcheck=1/c\gpgcheck=0" /etc/yum.repos.d/zabbix.repo
# 安装zabbix server、web前端、agent
yum -y install zabbix-server-mysql zabbix-agent
# 安装zabbix frontend
yum install centos-release-scl
sed -i "11c\enable=1" /etc/yum.repos.d/zabbix.repo
# 安装 zabbix frontend packages
yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl
install_mysql
sleep 2
clear
# 将zabbix-server端需要的初始表导入数据库中
read -p "请输入您root用户的数据库密码: " password
read -p "请输入您要创建的数据库名称,用于存放zabbix-server端的初始化表: " dbName
read -p "请输入你要创建的管理zabbix的用户名: " zName
read -p "请输入你要创建的管理zabbix的用户密码: " zPwd
mysql -uroot -p$password -e "create database $dbName character set utf8 collate utf8_bin;" 2>/dev/null
echo "创建初始库成功~"
mysql -uroot -p$password -e "grant all on $dbName.* to $zName@'%' identified by'$zPwd';" 2>/dev/null
echo "创建管理zabbix的用户成功~"
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$zName -p$zPwd $dbName 2>/dev/null
echo "初始表导入初始库成功~"
echo "数据库相关操作已配置完毕~~~"
sleep 2
echo -e "\n修改zabbix-server.conf文件中..."
sed -i "/# DBHost=localhost/c\DBHost=localhost" /etc/zabbix/zabbix_server.conf
sed -i "/DBName=zabbix/c\DBName=$dbName" /etc/zabbix/zabbix_server.conf
sed -i "/DBUser=zabbix/c\DBUser=$zName" /etc/zabbix/zabbix_server.conf
sed -i "/# DBPassword=/c\DBPassword=$zPwd" /etc/zabbix/zabbix_server.conf
sed -i "/; php_value\[date\.timezone\] = Europe\/Riga/c\php_value[date.timezone] = Asia/Shanghai" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
echo "修改zabbix-server.conf文件成功~~~"
echo "启动zabbix服务以及相关的服务中...."
systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
if [ $? -eq 0 ];then
	echo "启动成功~~~,请在浏览器中访问zabbix服务"
else
	echo "启动失败!!!,请检查配置文件是否配置错误"
fi
}

# install_zabbix
#fun() {
#read -p "请输入您root用户的数据库密码: " password
#read -p "请输入您要创建的数据库名称,用于存放zabbix-server端的初始化表: " dbName
#read -p "请输入你要创建的管理zabbix的用户名: " zName
#read -p "请输入你要创建的管理zabbix的用户密码: " zPwd
#mysql -uroot -p$password -e "create database $dbName character set utf8 collate utf8_bin;" 2>/dev/null
#echo "创建初始库成功~"
#mysql -uroot -p$password -e "grant all on $dbName.* to $zName@'%' identified by'$zPwd';" 2>/dev/null
#echo "创建管理zabbix的用户成功~"
#zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$zName -p$zPwd $dbName 2>/dev/null
#echo "初始表导入初始库成功~"
#echo "数据库相关操作已配置完毕~~~"
#sleep 2
#echo -e "\n修改zabbix-server.conf文件中..."
#sed -i "/# DBHost=localhost/c\DBHost=localhost" /etc/zabbix/zabbix_server.conf
#sed -i "/DBName=zabbix/c\DBName=$dbName" /etc/zabbix/zabbix_server.conf
#sed -i "/DBUser=zabbix/c\DBUser=$zName" /etc/zabbix/zabbix_server.conf
#sed -i "/# DBPassword=/c\DBPassword=$zPwd" /etc/zabbix/zabbix_server.conf
#sed -i "/; php_value\[date\.timezone\] = Europe\/Riga/c\php_value[date.timezone] = Asia/Shanghai" /etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
#echo "修改zabbix-server.conf文件成功~~~"
## 防止zabbix-server服务启动不了,关闭防火墙
#        systemctl stop firewalld
#        systemctl disable firewalld
#        setenforce 0
#        sed -ri "/^[ ]*SELINUX=/c\SELINUX=disabled" /etc/selinux/config
#
#echo "启动zabbix服务以及相关的服务中...."
#systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
#if [ $? -eq 0 ];then
#        echo "启动成功~~~,请在浏览器中访问zabbix服务"
#else
#	echo "启动失败!!!,请检查配置文件是否配置错误"
#fi
#}
# fun
