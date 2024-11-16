#!/bin/bash
# 新建虚拟机,初始化操作
source tools.sh
# 【一级菜单】
main_menu() {
echo -e "\e[36m -----------------【主菜单】------------------- \e[0m"
echo -e "\e[32m \t\t1.优化系统\t\t\t \e[0m"
echo -e "\e[32m \t\t2.安装服务\t\t\t \e[0m"
echo -e "\e[32m \t\t3.退出脚本\t\t\t \e[0m"
}
# 实现ssh公钥批量传输
# 生成ssh公私钥
sshkeygen_fun () {
/usr/bin/expect <<-EOF
spawn ssh-keygen
expect {
        "/root/.ssh/id_rsa" {send "\r";exp_continue}
        "empty for no passphrase" {send "\r";exp_continue}
        "Enter same passphrase again" {send "\r"}
}
expect eof;
EOF

}
# 传输公钥
sshcopy_fun() {
	read -p "请输入对应的网段: " ip_d
        for ((i=2; i<255; i++))
        do
	{	ip=$ip_d.$i
		local_ip=$(ip a| grep $ip_d | awk -F "[ /]*" '{print $3}')
          	if [ $ip == "$local_ip" ];then
			continue
		fi
		ping -c 1 $ip &> /dev/null
		if [ $? -eq 0 ];then
	                /usr/bin/expect <<-EOF
         	        spawn ssh-copy-id $ip  
	                expect {
				"continue connecting (yes/no)?" {send "yes\r";exp_continue}
          	        	"password:" {send "1\r"}
				}
			expect eof;
			EOF
		fi
        } &
	done
	wait
}
ssh_fun() {
	echo "正在下载expect、tcl,请稍等..."
	yum -y install expect tcl &> /dev/null
	# 判断当前机器是否有ssh公私钥
	if [ -f ~/.ssh/id_rsa -a -f ~/.ssh/id_rsa.pub ];then
        	echo "公私钥都存在,可以直接传输"
		sshcopy_fun
		echo "传输完成..."
	else
        	echo "公私钥不存在,需要先生成公私钥,请稍等..."
		sshkeygen_fun
		echo "公钥已生成,正在进行传输公钥,请稍等..."
		sshcopy_fun
	fi
}

# 【1.优化系统菜单】
menu1() {
clear
while :
do
echo -e "\e[35m -----------------【优化系统菜单】------------------- \e[0m"
echo -e "\e[33m \t\t【1】安装 YUM 源\t\t \e[0m"
echo -e "\e[33m \t\t【2】优化 ssh 连接\t\t \e[0m"
echo -e "\e[33m \t\t【3】永久关闭防火墙、selinux\t\t \e[0m"
echo -e "\e[33m \t\t【4】设置 IP 地址\t\t \e[0m"
echo -e "\e[33m \t\t【5】批量传输公钥,SSH免密连接\t\t \e[0m"
echo -e "\e[33m \t\t【6】对照时间(以ali的为准)\t\t \e[0m"
echo -e "\e[33m \t\t【0】返回主菜单\t\t \e[0m"
read -p "请输入要操作的内容【编号】: " num
case $num in
	"1")
	mkdir /etc/yum.repos.d/back &> /dev/null
	mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/back
	echo "请稍等..."
	curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	curl -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all
	echo "清理缓存..."
	echo "正在建立新缓存中..."
	yum makecache
	clear
	echo -e "\e[42;37m 安装 ali yum源和 ali 扩展源成功,请自行清空缓存,并重新生成缓存,避免影响后续操作... \e[0m"
	;;
	"2")
	sed -ri "/^#.*DNS/c\UseDNS no" /etc/ssh/sshd_config
	systemctl restart sshd
	clear
	echo -e "\e[42;37m 优化 ssh 连接成功 \e[0m"
	;;
	"3")
	systemctl stop firewalld
	systemctl disable firewalld
	setenforce 0
	sed -ri "/^[ ]*SELINUX=/c\SELINUX=disabled" /etc/selinux/config
	clear
	echo -e "\e[42;37m 永久关闭防火墙、selinux成功 \e[0m"
	;;
	"4")
	read -p "请输入网关: " gw
	read -p "请输入IP: " ip
	echo -e "TYPE=\"Ethernet\"\nBOOTPROTO=\"none\"\nDEVICE=\"ens33\"\nONBOOT=\"yes\"\nIPADDR=$ip\nPREFIX=24\nGATEWAY=$gw\nDNS1=114.114.114.114" > /etc/sysconfig/network-scripts/ifcfg-ens33
	echo -e "\e[42;37m 设置 IP 地址成功,网卡已重新启动,注意切换新ip,再使用第三方软件进行连接 \e[0m"
	systemctl restart network
	;;
	"5")
	clear
	ssh_fun
	echo -e "\e[42;37m 已经向对应网段中可以ping通的机器发送了ssh公钥 \e[0m"
	break
	;;
	"6")
	clear
	echo "修改前的时间"
	date
	echo "对照ali时间中..."
	yum -y install ntpdate
	ntpdate ntp.aliyun.com
	echo "修改之后的时间"
	date
	break
	;;
	"0")
	clear
	echo -e "\e[43;37m 已返回主菜单 \e[0m"
	break
	;;
	*)
	clear
	echo -e "\e[41;37m 输入错误,请按照要求正确输入!!! \e[0m"
	sleep 1
	continue
	;;
esac
done
}
# 【2.安装服务】
menu2() {
clear
while :
do
echo -e "\e[35m -----------------【安装服务】------------------- \e[0m"
echo -e "\e[33m \t\t【1】安装 httpd\t\t \e[0m"
echo -e "\e[33m \t\t【2】安装 nginx\t\t \e[0m"
echo -e "\e[33m \t\t【3】yum 安装 mysql\t\t \e[0m"
echo -e "\e[33m \t\t【4】常用软件包(vim、net-tools、wget...)\t\t\n \e[0m"
echo -e "\e[33m \t\t【5】部署 jenkins 并做初始化配置\t\t\n \e[0m"
echo -e "\e[33m \t\t【6】安装 gitlab 并做初始化配置\t\t\n \e[0m"
echo -e "\e[33m \t\t【7】安装 zabbix 并做初始化配置\t\t\n \e[0m"
echo -e "\e[33m \t\t【9】返回主菜单\t\t \e[0m"
read -p "请输入要操作的内容【编号】: " num
case $num in
        "1")
	clear
	yum -y install httpd &> /dev/null
	if [ $? -eq 0 ];then
        	echo -e "\e[42;37m 安装 httpd 成功 \e[0m"
       	else
		echo -e "\e[41;37m 安装失败,请稍后重试!!! \e[0m"
	fi
	;;
        "2")
	clear
	echo "创建nginx.repo仓库..."
	echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true' > /etc/yum.repos.d/nginx.repo
	sleep 1
	echo "nginx.repo仓库创建成功,正在安装..."
	yum -y install nginx &> /dev/null
	if [ $? -eq 0 ];then
		echo -e "\e[42;37m 安装 nginx 成功 \e[0m"
		echo "使用 nginx -V 查看配置信息"
        else 
		echo -e "\e[41;37m 安装失败,请稍后重试!!! \e[0m"
	fi
	;;
        "3")
	clear
	install_mysql
        ;;
        "4")
        yum -y install wget vim net-tools bash-completion
        clear
        echo -e "\e[42;37m 常用软件安装成功 \e[0m"
        ;;
	"5")
	clear
	init_jenkins
	echo -e "\e[42;37m jenkins已经成功部署,通过浏览器即可访问 \e[0m"
	;;
	"6")
	clear
	install_gitlab
	echo -e "\e[42;37m gitlab已将安装并初始化完成... \e[0m"
	;;
	"7")
	clear
	install_zabbix
	echo -e "\e[42;37m zabbix服务端,以及相关服务都已安装成功 \e[0m"
	;;
        "9")
        clear
        echo -e "\e[43;37m 已返回主菜单 \e[0m"
        break
        ;;
        *)
	clear
        echo -e "\e[41;37m 输入错误,请按照要求正确输入!!! \e[0m"
        sleep 1
        continue
        ;;
esac
done
}


while :
do
main_menu
read -p "请输入你想要进行的操作【对应的编号】: " choice
case $choice in
	"1")
	menu1
	;;
	"2")
	menu2
	;;
	"3")
	echo -e "\e[42;37m 正常退出脚本~~~ \e[0m"
	sleep 1
	exit 0
	;;
	*)
	echo "输入错误,请按照要求正确输入!!!"
	sleep 2
	continue
	;;
esac

done

