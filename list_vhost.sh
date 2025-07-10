#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

vhost_info() {
    local domain=$1
    local limit=1
    local conf_file="/etc/apache2/sites-available/${domain}.conf"

    echo -e "${GREEN}➤ User sở hữu:     ${RESET}$(grep "DocumentRoot" "$conf_file" | cut -d/ -f3)"
    echo -e "${GREEN}➤ ServerName:      ${RESET}$(grep "ServerName" "$conf_file" | awk '{print $2}')"
    echo -e "${GREEN}➤ File config:     ${RESET}${domain}.conf"
    echo -e "${GREEN}➤ DocumentRoot:    ${RESET}$(grep "DocumentRoot" "$conf_file" | awk '{print $2}')"
    echo -e "${GREEN}➤ PHP Version:     ${RESET}$(grep -Eo "php[0-9]\.[0-9]" "$conf_file")"

    if [[ $limit -eq 2 ]]; then
        exit
    fi

    if [[ -f "/etc/apache2/sites-available/${domain}-le-ssl.config" ]]; then
        limit=2
        vhost_info "${domain}-le-ssl"
    fi
}

main() {
    local domain 
    while true; do
        echo -e "${BLUE}---------------- DANH SÁCH CÁC CẤU HÌNH VHOST HIỆN CÓ ----------------${RESET}"
        list_vhost=$(ls /etc/apache2/sites-available)
        echo -e "${YELLOW}$list_vhost${RESET}"
        echo -e "1) 🔍 ${GREEN}Xem cấu hình cơ bản Vhost${RESET}"
        echo -e "2) 🛠️  ${GREEN}Xem tập tin cấu hình đầy đủ${RESET}"
        echo -e "3) ❌ ${RED}Thoát${RESET}"
        echo ""

        read -p "👉 LỰA CHỌN: " choice

        if [[ $choice -eq 1 ]]; then
            read -p "🌐 Nhập tên miền (không nhập .conf): " domain
            if ! ./check_domain_exist.sh ${domain} ; then
                echo -e "${RED}❌ File cấu hình tương ứng với domain này không tồn tại${RESET}"
                sleep 2
                continue
            fi
            vhost_info $domain

        elif [[ $choice -eq 2 ]]; then
            read -p "🌐 Nhập tên miền (không nhập .conf): " domain
            cat /etc/apache2/sites-available/${domain}.conf > result_temp
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}📂 Thông tin chi tiết cấu hình domain ${domain}:${RESET}"
                echo -e "${BLUE}------------------------${RESET}"
                cat result_temp
                echo -e "${BLUE}------------------------${RESET}"
                rm -f result_temp
                if [[ -f /etc/apache2/sites-available/${domain}-le-ssl.conf ]]; then
                    echo -e "${YELLOW}🔒 Cấu hình SSL kèm theo:${RESET}"
                    cat /etc/apache2/sites-available/${domain}-le-ssl.conf
                fi
            else
                echo -e "${RED}❌ Domain không tồn tại. Vui lòng thử domain khác${RESET}"
            fi
            read -p "🔁 Nhấn ENTER để tiếp tục..."

        elif [[ $choice -eq 3 ]]; then
            echo -e "${RED}👋 Thoát chương trình xem cấu hình Vhost...${RESET}"
            exit

        else
            echo -e "${YELLOW}⚠️  Lựa chọn không hợp lệ. Vui lòng thử lại.${RESET}"
            read -p "🔁 Nhấn ENTER để tiếp tục..."
        fi
    done
}

main "$@"
