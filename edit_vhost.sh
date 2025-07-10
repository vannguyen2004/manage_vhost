#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

change_php_version(){
    local domain=$1
    local php_version=$2
    local limit=0

    echo -e "${BLUE}🔧 Đang thay đổi PHP version cho ${domain}...${RESET}"
    a2dissite "$domain.conf"
    find "/etc/apache2/sites-available/" -type f -name "${domain}.conf" -exec sed -i "s/php[0-9]\.[0-9]/php${php_version}/g" {} \;

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Đã xảy ra lỗi khi thay đổi PHP version. Vui lòng kiểm tra lại.${RESET}"
        exit
    fi
    apache2ctl configtest > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
            echo -e "${RED}❌ Lỗi cấu hình Apache sau khi thay đổi PHP. Vui lòng kiểm tra file config.${RESET}"
            exit
    fi
    a2ensite "$domain" > /dev/null 2>&1
    if [[ -f "/etc/apache2/sites-available/${domain}-le-ssl.conf" ]] || [[ ! $limit -ne 2 ]] ; then
        limit=2
        change_php_version "${domain}-le-ssl"
    fi
     systemctl reload apache2.service
}

change_domain(){
    local old_domain=$1
    local new_domain=$2

    echo -e "${YELLOW}🔁 Đang thay đổi domain từ ${old_domain} → ${new_domain}${RESET}"
    a2dissite "$old_domain.conf"
    cp "/etc/apache2/sites-available/${old_domain}.conf" "/etc/apache2/sites-available/${new_domain}.conf"

    sudo sed -i \
        -e "s/ServerName\s\+${old_domain}/ServerName ${new_domain}/" \
        -e "s/ServerAlias\s\+www.${old_domain}/ServerAlias www.${new_domain}/" \
        -e "s|/home/\([^/]\+\)/${old_domain}|/home/\1/${new_domain}|g" \
        -e "s|/var/log/apache2/\([^/]\+\)/${old_domain}/|/var/log/apache2/\1/${new_domain}/|g" \
        "/etc/apache2/sites-available/${new_domain}.conf"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Đã cập nhật file cấu hình. Xoá file cũ...${RESET}"
        rm "/etc/apache2/sites-available/${old_domain}.conf"
    else
        echo -e "${RED}❌ Thay đổi cấu hình thất bại. Vui lòng kiểm tra lại.${RESET}"
        exit
    fi

    account=$(grep "DocumentRoot" "/etc/apache2/sites-available/${new_domain}.conf" | cut -d'/' -f3)
    echo -e "${BLUE}👤 Tài khoản sở hữu: ${account}${RESET}"

    mv /home/${account}/$old_domain /home/${account}/$new_domain
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Đã cập nhật thư mục DocumentRoot${RESET}"
    else
        echo -e "${RED}❌ Không thể đổi tên thư mục web${RESET}"
    fi

    mv /var/log/apache2/${account}/$old_domain /var/log/apache2/${account}/$new_domain
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Đã cập nhật thư mục log domain${RESET}"
    else
        echo -e "${RED}❌ Không thể đổi tên thư mục log${RESET}"
    fi

    echo -e "${GREEN}🔔 ENABLE SITE ${new_domain}${RESET}"
    a2ensite ${new_domain}.conf

    if [[ -f "/etc/apache2/sites-available/${old_domain}-le-ssl.conf" ]]; then
        rm -f "/etc/apache2/sites-available/${old_domain}-le-ssl.conf"
    fi

    systemctl reload apache2.service
}

main(){
    local domain1 domain2 php_version
    while true; do
        echo -e "${GREEN}=========================================================="
        echo -e "          🛠️  ĐIỀU CHỈNH CẤU HÌNH VIRTUAL HOST"
        echo -e "==========================================================${RESET}"
        echo -e "\n1) 🔧 Thay đổi phiên bản PHP"
        echo -e "2) 🔁 Thay đổi domain của cấu hình Vhost"
        echo -e "3) 🔐 Reset mật khẩu database (chưa hỗ trợ)"
        echo -e "4) ❌ Thoát"
        echo ""

        read -p "👉 LỰA CHỌN: " choice
        case "$choice" in
            1)
                read -p "🌐 Nhập domain cần đổi PHP: " domain1
                if ./check_domain_exist.sh $domain1; then
                    read -p "📦 Nhập phiên bản PHP [7.1|7.2|7.3|7.4]: " php_version
                    change_php_version $domain1 $php_version
                else
                    echo -e "${RED}❌ Domain không tồn tại. Vui lòng thử lại.${RESET}"
                fi
                ;;
            2)
                read -p "🌐 Tên miền hiện tại: " domain1
                if ./check_domain_exist.sh $domain1; then
                    read -p "🆕 Tên miền mới: " domain2
                    if ! ./check_domain_exist.sh $domain2; then
                        change_domain $domain1 $domain2
                        echo -e "${GREEN}✅ Đổi tên miền thành công!${RESET}"
                    else
                        echo -e "${YELLOW}⚠️  Domain mới đã tồn tại. Vui lòng thử tên khác.${RESET}"
                    fi
                else
                    echo -e "${RED}❌ Domain hiện tại không tồn tại.${RESET}"
                fi
                ;;
            3)
                echo -e "${YELLOW}🚧 Chức năng reset mật khẩu database đang phát triển.${RESET}"
                ;;
            4)
                echo -e "${RED}🚪 Thoát chương trình điều chỉnh Virtual Host.${RESET}"
                exit
                ;;
            *)
                echo -e "${RED}⚠️  Lựa chọn không hợp lệ. Vui lòng thử lại.${RESET}"
                ;;
        esac
    done
}
main
