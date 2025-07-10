#!/bin/bash

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
	if [[ "$username" =~ ^[a-z]{8}$ ]]  && ! getent passwd "$username" > /dev/null && [[ ! -d /home/"$username" ]]; then
		sudo adduser "${username}"
	else 
		echo "${YELLOW}User không hợp lệ. Vui lòng kiểm tra lại Tên phải gồm đúng 8 ký tự chữ thường (a–z), không số, không ký tự đặc biệt và chưa tồn tại${RESET}"
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
	echo -e "${GREEN}Tạo thành công doc root và dir log$RESET}{"
	echo "Site ${domain} working" > "/home/${username}/${domain}/index.html"
	echo -e "<?php phpinfo(); ?>" > "/home/${username}/${domain}/info.php"
	echo -e "${GREEN}Đã tạo file test [ index.html, info.php ]${RESET}"
	chown -R "$username:$username" "/home/${username}/${domain}"
}
create_acc_db(){
	local username=$1
	if ! mariadb -e "SELECT user FROM mysql.user;" | grep -q "^${username}_$"; then
		mariadb -e "CREATE USER '${username}_'@'%' IDENTIFIED BY '${username}123'; FLUSH PRIVILEGES;"
		echo "Đã tạo user db: ${username}_  |  password: ${username}123"
		echo "${YELLOW}HÃY THAY ĐỔI MẬT KHẨU ĐỂ BẢO MẬT${RESET}"
	fi 
}
main(){
	local username domain php_version vhost_path
	vhost_path="/etc/apache2/sites-available"
while true; do 
	echo -e "${GREEN}=========================================================="
	echo -e "		CHƯƠNG TRÌNH TẠO VIRTUAL HOST CHO USER "
	echo -e "==========================================================${RESET}"
	echo -e "1)${YELLOW} Tạo virtual host cho user có sẵn${RESET}"
	echo -e "2) ${YELLOW} Tạo virtual host cho user mới${RESET}"
	echo -e "3) ${YELLOW} Thoát chương trình tạo virtual host${RESET}"
	read -p "LỰA CHỌN: " choice
	case "${choice}" in
		1)
			USER_EXIST=$(list_user)
			echo -e "Danh sáchh user hiện có:${BLUE} $USER_EXIST ${RESET}"
			read -p  "Vui lòng chọn user : " username
			found=0
			for user in ${USER_EXIST[@]}; do 
			    if [[ "${user}" == "$username" ]]; then
					     found=1
					     break
				fi    
		       done
		       if [[ $found -eq 1 ]]; then
			       echo "User hợp lệ"
		       else
			       echo "User không hợp lệ"
			       continue
		       fi  
		       ;;
	       2)
		      read -p "TẠO MỚI USER: " username 
		      check_user ${username}
		      ;;
	      3)
		      echo -e  "${RED}Thoát chương trình tại virtual host cho user${RESET}"
		      read 
		      break;
		      ;;
	      *)
		      echo -e  "${RED}Lựa chọn không hợp lệ nhấn enter để tiếp tục${RESET}"
		      read  
		      continue 
		      ;;
      esac
     echo -ne  "${BLUE}Domain của Vhost : ${RESET}"
     read  domain
     if [[ ! "$domain" =~ ^([a-z0-9][-a-z0-9]{0,62}\.)+[a-zA-Z0-9-]{2,63}$ ]]; then
	     echo -e "${RED}Domain không hợp lệ${RESET}"
	     continue 
     fi
     if ./check_domain_exist.sh $domain > /dev/null; then
 	     echo -e "${YELLOW}Domain ${domain} đã có trong cấu hình. Vui lòng kiểm tra lại hoặc liên hệ quản trị viên${RESET}"
	     continue 
     fi 
     echo -ne "${BLUE}Nhập phiên bản PHP của VHOST [7.1|7.2|7.3|7.3|7.4]: ${RESET}" 
     read php_version
     case "${php_version}" in
	     7.1|7.2|7.3|7.3|7.4)
		     create_config "${username}" "${domain}" "${php_version}"
		     create_directory "${username}" "${domain}"
		     create_acc_db "${username}"
		     apache2ctl configtest
		     if [[ $? -ne 0 ]];then
			     echo "${RED}ĐÃ XÃY RA LỖI CẤU HÌNH VUI LÒNG KIỂM TRA CẤU HÌNH${RESET}"
			     exit
		     fi 
		     echo "ENABLE SITE ${domain}"
		     a2ensite ${domain}
		     systemctl reload apache2.service
		     echo "${GREEN}TẠO VIRTUAL HOST THÀNH CÔNG DOMAIN${RESET} ${domain} ${GREEN}TRÊN TÀI KHOẢN USER${RESET} ${username}"
		     break 
		     ;;
	     *)
		     read -p "${RED}PHIÊN BẢN PHP KHÔNG HỢP LỆ, ẤN ENTER ĐỂ THỬ LẠI${RESET}" 
		     ;;
     esac 

done 
}
main "$@"



