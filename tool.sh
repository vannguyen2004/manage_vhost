#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

check_dns() {
    local domain=$1
    IPS=$(dig -t A "$domain" +short)
    if [ -z "$IPS" ]; then
        echo -e "${RED}⚠️ Domain ${domain} chưa trỏ về bản ghi A nào${RESET}"
        exit 1
    fi

    VPS_IP=$(hostname -I | awk '{print $1}')
    for IP in $IPS; do
        if [[ "$VPS_IP" == "$IP" ]]; then
            echo -e "${GREEN}✅ Domain ${domain} đang trỏ đúng về IP VPS: $IP${RESET}"
        else
            echo -e "${YELLOW}🔁 Domain ${domain} đang trỏ về IP khác: $IP${RESET}"
        fi
    done
}

install_ssl_certbot() {
    local domain="$1"
    echo -e "${BLUE}🚀 Tiến hành cài đặt SSL bằng Certbot cho domain: ${domain}${RESET}"
    sleep 1
    sudo certbot --apache -d "$domain" --non-interactive --agree-tos -m "admin@${domain}"
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Cài đặt SSL thành công! Reload Apache...${RESET}"
        sudo systemctl reload apache2
    else
        echo -e "${RED}❌ SSL cài đặt thất bại! Kiểm tra lại IP đã trỏ đúng chưa.${RESET}"
    fi
}

backup() {
    local username=$1
    local user_db="${username}_"
    local time=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_dir="/home/$username/backup"
    local backup_name="${username}-${time}.tar.gz"

    echo -e "${BLUE}💾 Tiến hành backup dữ liệu cho user: ${username}${RESET}"
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
        chown $username:$username $backup_dir
    fi

    databases=$(mysql -e "SHOW DATABASES;" | grep "^${user_db}")
    for database in $databases; do
        mysqldump -u root "$database" > "${backup_dir}/${database}_$backup_name.sql"
    done

    tar -cvzf "${backup_dir}/${backup_name}" "/home/$username/"
    echo -e "${GREEN}✅ Backup thành công! Đã lưu tại ${backup_dir}${RESET}"
}

setup_wordpress() {
    local domain=$1
    local user=$(grep "DocumentRoot" "/etc/apache2/sites-available/${domain}.conf" | cut -d/ -f3)
    doc_root=$(grep "DocumentRoot" "/etc/apache2/sites-available/${domain}.conf" | awk '{print $2}')

    if [[ -z "$(ls -A "${doc_root}")" ]]; then
        echo -e "${BLUE}📦 Tải source WordPress về...${RESET}"
        git clone https://github.com/WordPress/WordPress.git
        mv ./WordPress/* "$doc_root"
        chown -R $user:$user $doc_root
        rm -rf ./WordPress
        

        read -p "🔧 Nhập tên database cần tạo: " db_name
        mysql -e "CREATE DATABASE ${user}_${db_name};" > /dev/null

        if [[ $? -eq 0 ]]; then
            mysql -e "GRANT ALL ON \`${user}_${db_name}\`.* TO '${user}_'@'%';"
            mysql -e "FLUSH PRIVILEGES;"
            echo -e "Database name của bạn là: ${user}_${db_name}"
            echo -e "${GREEN}✅ Đã tạo database và phân quyền cho user ${user}${RESET}"
        else
            echo -e "${RED}❌ Database đã tồn tại hoặc lỗi khi tạo${RESET}"
        fi
    else
        echo -e "${YELLOW}⚠️ Thư mục doc root của domain ${domain} đã có dữ liệu, không thể ghi đè${RESET}"
    fi
}

main() {
while true; do
    echo -e "${BLUE}================== HƯỚNG DẪN CHƯƠNG TRÌNH ==================${RESET}"
    echo -e "1) 🔍 Kiểm tra thông tin domain (Vhost)"
    echo -e "2) 🔐 Cài đặt SSL Let's Encrypt cho domain"
    echo -e "3) 💾 Tạo backup (code + database)"
    echo -e "4) 🌐 Cấu hình DNS Cloudflare"
    echo -e "5) 🧩 Setup WordPress"
    echo -e "0) 🚪 Thoát chương trình"
    echo -e "-------------------------------------------------------------"
    read -p "👉 Vui lòng chọn một chức năng [0-5]: " choice

    case "$choice" in
        1)
            echo -e "${BLUE}🔍 BẠN ĐÃ CHỌN: Kiểm tra domain${RESET}"
            read -p "🌐 Nhập domain: " domain
            check_dns $domain
            ;;
        2)
            echo -e "${BLUE}🔐 BẠN ĐÃ CHỌN: Cài đặt SSL${RESET}"
            read -p "🌐 Nhập domain cần cài SSL: " domain
            if ./check_domain_exist.sh $domain; then
                install_ssl_certbot $domain
            else
                echo -e "${RED}❌ Domain ${domain} chưa tồn tại!${RESET}"
            fi
            ;;
        3)
            echo -e "${BLUE}💾 BẠN ĐÃ CHỌN: Backup người dùng${RESET}"
            read -p "👤 Nhập tên user cần backup: " username
            if getent passwd "${username}" && [[ -d /home/${username} ]]; then
                backup $username
            else
                echo -e "${RED}❌ User không hợp lệ!${RESET}"
            fi
            ;;
        4)
            echo -e "${BLUE}🌐 BẠN ĐÃ CHỌN: Cấu hình DNS Cloudflare${RESET}"
            bash ./dns_cf.sh
            ;;
        5)
            echo -e "${BLUE}🧩 BẠN ĐÃ CHỌN: Setup WordPress${RESET}"
            read -p "🌐 Nhập domain cần setup: " domain
            if ./check_domain_exist.sh $domain; then
                setup_wordpress $domain
            else
                echo -e "${RED}❌ Domain không tồn tại!${RESET}"
            fi
            ;;
        0)
            echo -e "${GREEN}👋 Thoát chương trình. Hẹn gặp lại!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Lựa chọn không hợp lệ. Vui lòng nhập từ 0 đến 5.${RESET}"
            ;;
    esac

    read -p "🔁 Nhấn Enter để quay lại menu..."
    clear
done
}
main
