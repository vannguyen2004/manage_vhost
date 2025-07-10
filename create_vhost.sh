#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

list_user() {
  list=()
  for dir in /home/*; do
      user=$(basename "$dir")
      if getent passwd "$user" > /dev/null; then
          list+="$user "
      fi
  done
  echo $list
}

check_user(){
	local username=$1
	if [[ "$username" =~ ^[a-z]{8}$ ]] && ! getent passwd "$username" > /dev/null && [[ ! -d /home/"$username" ]]; then
		sudo adduser "${username}"
	else 
		echo -e "${YELLOW}⚠️  User không hợp lệ. Vui lòng kiểm tra lại!\nTên phải gồm đúng 8 ký tự chữ thường (a–z), không số, không ký tự đặc biệt và chưa tồn tại.${RESET}"
		exit 1
	fi 
}

create_config() {
    local username="$1"
    local domain="$2"
    local php_version="$3"
    local vhost_path="/etc/apache2/sites-available"

    sudo tee "$vhost_path/${domain}.conf" > /dev/null <<EOF
<VirtualHost *:80>
    DocumentRoot /home/${username}/${domain}
    ServerName ${domain}
    ServerAlias www.${domain}
    ServerAdmin admin@${domain}
    ErrorLog /var/log/apache2/${username}/${domain}/error.log
    CustomLog /var/log/apache2/${username}/${domain}/access.log combined
    <Directory "/home/${username}/${domain}">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
        <FilesMatch \.php$>
            SetHandler "proxy:unix:/run/php/php${php_version}-fpm.sock|fcgi://localhost"
        </FilesMatch>
    </Directory>
</VirtualHost>
EOF
}

create_directory(){
	local username=$1
	local domain=$2
	mkdir -p "/home/${username}/${domain}"
	mkdir -p "/var/log/apache2/${username}/${domain}"
	echo -e "${GREEN}📁 Tạo thành công doc root và thư mục log${RESET}"
	echo "Site ${domain} working" > "/home/${username}/${domain}/index.html"
	echo -e "<?php phpinfo(); ?>" > "/home/${username}/${domain}/info.php"
	echo -e "${GREEN}📝 Đã tạo file test [index.html, info.php]${RESET}"
	chown -R "$username:$username" "/home/${username}/${domain}"
}

create_acc_db(){
	local username=$1
	if ! mariadb -e "SELECT user FROM mysql.user;" | grep -q "^${username}_$"; then
		mariadb -e "CREATE USER '${username}_'@'%' IDENTIFIED BY '${username}123'; FLUSH PRIVILEGES;"
		echo -e "${GREEN}🐘 Đã tạo user DB: ${username}_  |  Password: ${username}123${RESET}"
		echo -e "${YELLOW}⚠️  HÃY THAY ĐỔI MẬT KHẨU ĐỂ BẢO MẬT${RESET}"
	fi 
}

main(){
	local username domain php_version vhost_path
	vhost_path="/etc/apache2/sites-available"

	while true; do 
		echo -e "${GREEN}=========================================================="
		echo -e "		💻 CHƯƠNG TRÌNH TẠO VIRTUAL HOST CHO USER "
		echo -e "==========================================================${RESET}"
		echo -e "1) ${YELLOW}🧑‍💻 Tạo virtual host cho user có sẵn${RESET}"
		echo -e "2) ${YELLOW}✨ Tạo virtual host cho user mới${RESET}"
		echo -e "3) ${YELLOW}❌ Thoát chương trình tạo virtual host${RESET}"
		
		read -p "👉 LỰA CHỌN: " choice
		case "${choice}" in
			1)
				USER_EXIST=$(list_user)
				echo -e "📋 Danh sách user hiện có: ${BLUE}$USER_EXIST${RESET}"
				read -p "👤 Vui lòng chọn user: " username
				found=0
				for user in ${USER_EXIST[@]}; do 
					if [[ "${user}" == "$username" ]]; then
						found=1
						break
					fi    
				done
				if [[ $found -eq 1 ]]; then
					echo -e "${GREEN}✅ User hợp lệ${RESET}"
				else
					echo -e "${RED}❌ User không hợp lệ${RESET}"
					continue
				fi  
				;;
			2)
				read -p "➕ TẠO MỚI USER: " username 
				check_user ${username}
				;;
			3)
				echo -e "${RED}🚪 Thoát chương trình tạo virtual host cho user${RESET}"
				read
				break;
				;;
			*)
				echo -e "${RED}❌ Lựa chọn không hợp lệ. Nhấn Enter để tiếp tục${RESET}"
				read  
				continue 
				;;
		esac

		echo -ne "${BLUE}🌐 Domain của Vhost: ${RESET}"
		read domain
		if [[ ! "$domain" =~ ^([a-z0-9][-a-z0-9]{0,62}\.)+[a-zA-Z0-9-]{2,63}$ ]]; then
			echo -e "${RED}❌ Domain không hợp lệ${RESET}"
			continue 
		fi

		if ./check_domain_exist.sh $domain > /dev/null; then
			echo -e "${YELLOW}⚠️  Domain ${domain} đã có trong cấu hình. Vui lòng kiểm tra lại hoặc liên hệ quản trị viên${RESET}"
			continue 
		fi 

		echo -ne "${BLUE}🔧 Nhập phiên bản PHP của VHOST [7.1|7.2|7.3|7.4]: ${RESET}" 
		read php_version
		case "${php_version}" in
			7.1|7.2|7.3|7.4)
				create_config "${username}" "${domain}" "${php_version}"
				create_directory "${username}" "${domain}"
				create_acc_db "${username}"
				apache2ctl configtest > /dev/null 2>&1
				if [[ $? -ne 0 ]]; then
					echo -e "${RED}❌ ĐÃ XẢY RA LỖI CẤU HÌNH. VUI LÒNG KIỂM TRA LẠI.${RESET}"
					exit
				fi 
				echo "🟢 ENABLE SITE ${domain}"
				a2ensite ${domain}
				systemctl reload apache2.service
				echo -e "${GREEN}✅ TẠO VIRTUAL HOST THÀNH CÔNG\n🌐 DOMAIN: ${domain}\n👤 USER: ${username}${RESET}"
				break 
				;;
			*)
				echo -e "${RED}❌ PHIÊN BẢN PHP KHÔNG HỢP LỆ. ẤN ENTER ĐỂ THỬ LẠI${RESET}" 
    				read
				;;
		esac 
	done 
}
main
