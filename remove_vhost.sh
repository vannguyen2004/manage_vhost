#!/bin/bash

delete_file_config(){
        local domain=$1
        local limit=1
        a2dissite ${domain}.conf > /dev/null
        sudo find /etc/apache2/sites-available -type f -name "${domain}.conf" -exec rm {} \; > /dev/null 2>&1
        sudo find /var/log/apache2/ -type d -name ${domain} -exec rm -rf {} \; > /dev/null 2>&1
        apache2ctl configtest
        if [[ $? -ne 0 ]]; then
                echo "${YELLOW}Đã xãy ra lỗi vui lòng kiểm tra các bước đã thực hiện ${RESET}"
                exit
        fi
        if [[ $limit -eq 2 ]];then
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
        echo "=========================================================="
        echo "          CHƯƠNG TRÌNH XÓA CẤU HÌNH VHOST"
        echo "=========================================================="
        read -p  "BẠN CÓ CẦN XEM LẠI CÁC FILE CẤU HÌNH HAY KHÔNG [y/N]" choice
        if [[ "$choice" == [yY] ]]; then
              bash ./list_vhost.sh
        fi
        read -p "NHẬP TÊN SITE MÀ BẠN MUỐN XÓA: " domain
        if  ! ./check_domain_exist.sh  $domain ; then
                echo "SITE CÓ DOMAIN ${domain} KHÔNG TỒN TẠI TRÊN HỆ THỐNG VUI LÒNG THỬ LẠI"
                continue
        fi
        read -p "BẠN CHẮC CHẮN MUỐN XÓA FILE CẤU HÌNH VIRTUAL HOST VỚI DOMAIN ${domain} NÀY CHỨ [y/N]: " confirm
        if [[ "$confirm" == [yY] ]]; then
                delete_file_config $domain
        else
                read -p "NHẤN ENTER ĐỂ QUAY LẠ'"

        fi
done
}
main 


