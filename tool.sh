#!/bin/bash 
check_dns() {
    local domain=$1
    IPS=$(dig -t A  "$domain" +short)
    if [ -z "$IPS" ]; then
        echo "Domain $domain chưa trỏ về bản ghi A nào"
        exit 1
    fi
    VPS_IP=$(hostname -I | awk '{print $1}')
    for IP in $IPS; do
            if [[ "$VPS_IP" == "$IP" ]]; then
                    echo "Domain $domain đang trỏ về IP VPS: $IP"
            else
                    echo "Domain $domain đang trỏ về IP: $IP"
            fi
    done
}
install_ssl_certbot() {
    local domain="$1" 
    echo -e "🚀 Tiến hành cài đặt SSL bằng certbot cho domain: $domain$"
    sleep 1
    sudo certbot --apache -d "$domain" --non-interactive --agree-tos -m "admin@${domain}"
    if [[ $? -eq 0 ]]; then
            echo -e "✅ Cài đặt SSL thành công! Reload Apache..."
            sudo systemctl reload apache2
    else
            echo -e "SSL cài đặt thất bại, kiểm tra IP đã trỏ về VPS chưa nhé"
    fi
}
backup(){
        local username=$1
        local user_db="${username}_"
        local time=$(date +"%Y-%m-%d_%H-%M-%S")
        local backup_dir="/home/$username/backup"
        local backup_name="${username}-${time}.tar.gz"
        echo "Tien hanh backup nguoi dung"
        if [[ ! -d "/home/$username/backup/" ]]; then
                mkdir /home/$username/backup/
                chown $username:$username $backup_dir
        fi
        databases=$(mysql -e "SHOW DATABASES;" |  grep "^$username_")
        for database in $databases; do
                mysqldump -u root "$database" > "${backup_dir}/${database}_$backup_name.sql"
        done
        tar -cvzf "${backup_dir}/${backup_name}" "/home/$username/"
        echo "Backup thành công thư mục người dùng và database cho user ${username}"
}
setup_wordpress(){
	local domain=$1
	local user=$(grep "DocumentRoot" "/etc/apache2/sites-available/${domain}.conf" | cut -d/ -f3)
	doc_root=$(grep "DocumentRoot" "/etc/apache2/sites-available/${domain}.conf" | awk '{print $2}')
	if [[ -z "$(ls -A "${doc_root}")" ]];then 
		git clone https://github.com/WordPress/WordPress.git
		mv ./WordPress/* $doc_root
		rm -rf ./WordPress
		read -p "Tạo database cho. Nhập tên database: " db_name
		mysql -e "create database ${user}_${db_name};" > /dev/null
		if [[ $? -eq 0 ]]; then
			#mysql -e "grant all on '${user}_${db_name}'.* to '${user}'@'%';"
			mysql -e "GRANT ALL ON \`${user}_${db_name}\`.* TO '${user}'@'%';"
			mysql -e "FLUSH PRIVILEGES;"
		else
			echo "database đã tồn tại vui lòng thử lại"
		fi
	else 
		echo "Trong thư mục doc root của domain ${domain} đã tồn tại dữ liệu"
	fi 
}
main(){
while true; do
    echo -e "================ HƯỚNG DẪN CHƯƠNG TRÌNH ================="
    echo -e "1) Kiểm tra thông tin domain (Vhost)"
    echo -e "2) Cài đặt SSL Let's Encrypt cho domain"
    echo -e "3) Tạo thư mục backup (code + database)"
    echo -e "4) Cấu hình DNS Cloudflare"
    echo -e "5) Setup Wordpress"
    echo -e "0) Thoát chương trình"
    echo -e "---------------------------------------------------------"
    read -p "👉 Vui lòng chọn một chức năng [0-4]: " choice
    case "$choice" in
            1)
            echo -e "🔍 BẠN ĐÃ CHỌN: Kiểm tra domain"
            # Gọi hàm kiểm tra domain hoặc script riêng ở đây
            read -p "Nhập domain mà bạn muốn kiểm tra: " domain
            check_dns $domain
            ;;
        2)
            echo -e "${GREEN}🔐 BẠN ĐÃ CHỌN: Cài đặt SSL cho domain${NC}"
            read -p "Nhập domain mà bạn muốn cài ssl: " domain
            if ./check_domain_exist.sh $domain ; then
            # Gọi hàm cài SSL hoặc script riêng ở đây
                install_ssl_certbot $domain
            else
                    echo "Domain ${domain} chưa tồn tại"
            fi

            break
            ;;
        3)
            echo -e "💾 BẠN ĐÃ CHỌN: Tạo thư mục backup"
            read -p "Nhập user mà ban muốn backup: " username
            if getent passwd "${username}" && [[ -d /home/${username} ]]; then
                    backup $username
            # Gọi hàm tạo backup hoặc script riêng ở đây
            else
            echo "User mà bạn nhập vào không hợp lệ"
            fi
            ;;
    4)
            ./dns_cf.sh
            ;;
    5)    
         read -p  "Bạn muốn setup wordpress cho domain nào: " domain
		 if ./check_domain_exist.sh $domain ; then
			 setup_wordpress $domain
		 else
			 echo "Domain không tồn tại xin vui lòng thử lại"
		 fi 
		 ;;
        0)
            echo -e "👋 Thoát chương trình. Hẹn gặp lại!"
            exit 0
            ;;
        *)
            echo -e "❌ Lựa chọn không hợp lệ. Vui lòng nhập từ 0 đến 4."
            ;;
    esac
    read -p "Nhấn Enter để quay lại menu..."
    clear
done
}
main




























