#!/bin/bash

vhost_info() {
    local domain=$1
    local limit=1
    local conf_file="/etc/apache2/sites-available/${domain}.conf"
    echo -e "${GREEN}➤ User sở hữu:  ${RESET}$(grep "DocumentRoot" "$conf_file" | cut -d/ -f3)"
    echo -e "${GREEN}➤ ServerName:   ${RESET}$(grep "ServerName" "$conf_file" | awk '{print $2}')"
    echo -e "${GREEN}➤ File config:  ${RESET}$domain.conf"
    echo -e "${GREEN}➤ DocumentRoot: ${RESET}$(grep "DocumentRoot" "$conf_file" | awk '{print $2}')"
    echo -e "${GREEN}➤ PHP Version:  ${RESET}$(grep -Eo "php[0-9]\.[0-9]" "$conf_file")"
    if [[ $limit -eq 2 ]];then
            exit
    fi
    if [[ -f "/etc/apache2/sites-avaliable/${domain}-le-ssl.config" ]]; then
            limit=2
            vhost_info "${domain}-le-ssl.conf"
            exit
    fi
}
main(){
        local domain 
while true; do
        echo "----------------DANH SÁCH CÁC CẤU HÌNH VHOST HIỆN CÓ----------------"
        list_vhost=$(ls /etc/apache2/sites-available)
        echo -e "${BLUE}${list_vhost} ${RESET}"
        echo "1) XEM CẤU HÌNH CƠ BẢN VHOST"
        echo "2) XEM TẬP TIN CẤU HÌNH"
        echo "3) THOÁT"
        read -p "LỰA CHỌN: " choice
        if [[ $choice -eq 1 ]]; then
                read -p  "Mời bạn nhập tên miền của tập tin cấu hình (không nhập .conf): " domain
                if  ! ./check_domain_exist.sh ${domain} ; then
                        echo "FILE CẤU HÌNH TƯƠNG ỨNG VỚI DOMAIN NÀY KHÔNG TỒN TẠI"
                        sleep 2
                        continue
                fi
                        vhost_info $domain
        elif [[ $choice -eq 2 ]]; then
                read -p  "Mời bạn nhập tên miền của tập tin cấu hình (không nhập .conf): " domain
                cat /etc/apache2/sites-available/${domain}.conf > result_temp
                if [[ $? -eq 0 ]]; then
                        echo "Thông tin chi tiết cấu hình domain ${domain}"
                        cat result_temp
                        rm -f result_temp
                       if [[ -f /etc/apache2/sites-available/${domain}-le-ssl.conf ]]; then
                               cat /etc/apache2/sites-available/${domain}-le-ssl.conf
                       fi
               else
                       echo -e "${RED} Domain  không tồn tại vui lòng thử domain khác${RESET}"
                fi
                read -p "NHẤN ENTER ĐỂ TIẾP TỤC"
        elif [[ $choice -eq 3 ]]; then
                echo "THOÁT...."
                exit
        else
                echo "LỰA CHỌN KHÔNG HỢP LỆ VUI LÒNG THỬ LẠI"
                read -p "NHẤN ENTER ĐỂ TIẾP TỤC"
        fi
done
}
main "$@"
