#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

delete_file_config(){
    local domain=$1
    local limit=1

    a2dissite ${domain}.conf > /dev/null
    sudo find /etc/apache2/sites-available -type f -name "${domain}.conf" -exec rm {} \; > /dev/null 2>&1
    sudo find /var/log/apache2/ -type d -name ${domain} -exec rm -rf {} \; > /dev/null 2>&1

    apache2ctl configtest
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  Đã xảy ra lỗi. Vui lòng kiểm tra lại các bước đã thực hiện.${RESET}"
        exit
    fi

    if [[ $limit -eq 2 ]]; then
        exit
    fi

    if ./check_domain_exist.sh "$domain-le-ssl"; then
        limit=2
        delete_file_config "${domain}-le-ssl"
        exit
    fi
}

main(){
    local domain 

    while true; do
        echo -e "${RED}=========================================================="
        echo -e "          🗑️  CHƯƠNG TRÌNH XÓA CẤU HÌNH VIRTUAL HOST"
        echo -e "==========================================================${RESET}"

        read -p "📋 Bạn có cần xem lại danh sách cấu hình trước khi xoá không? [y/N]: " choice
        if [[ "$choice" == [yY] ]]; then
            bash ./list_vhost.sh
        fi

        read -p "🌐 Nhập tên domain của site bạn muốn xoá: " domain
        if ! ./check_domain_exist.sh $domain ; then
            echo -e "${RED}❌ Site có domain ${domain} không tồn tại trên hệ thống. Vui lòng thử lại.${RESET}"
            continue
        fi

        read -p "⚠️  Bạn chắc chắn muốn xoá Virtual Host với domain ${domain}? [y/N]: " confirm
        if [[ "$confirm" == [yY] ]]; then
            delete_file_config $domain
            echo -e "${GREEN}✅ Đã xoá cấu hình Virtual Host cho domain ${domain}.${RESET}"
        else
            read -p "🔁 Nhấn ENTER để quay lại..."
        fi
    done
}
main
