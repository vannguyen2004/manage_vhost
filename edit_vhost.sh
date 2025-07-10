#!/bin/bash

change_php_version(){
        local domain=$1
        local php_version=$2
        local limit=0
        echo "abc"
        a2dissite "$domain.conf"
        find "/etc/apache2/sites-available/" -type f -name "${domain}.conf" -exec sed -i "s/php[0-9]\.[0-9]/php${php_version}/g" {} \;
        if [[ $? -ne 0 ]]; then
                echo "ĐÃ CÓ LỖI XẢY RA KHI THAY ĐỔI PHP VUI LÒNG KIỂM TRA CÁC BƯỚC ĐÃ THỰC HIỆN"
                exit
        fi
        apache2ctl configtest 
        if [[ $? -ne 0 ]]; then
                echo "ĐÃ CÓ LỖI XẢY RA KHI KIỂM TRA BẰNG pache2ctl configtest VUI LÒNG KIỂM TRA CÁC BƯỚC ĐÃ THỰC HIỆN"
                exit
        fi
        a2ensite "$domain.conf"
        systemctl reload apache2.service
        if [[ $limit -eq 1 ]];then
                exit
        fi
        if [[ -f "/etc/apache2/sites-available/${domain}-le-ssl.conf" ]]; then
                limit=1
                change_php_version "${domain}-le-ssl"
                exit
        fi
}
change_domain(){
        local old_domain=$1
        local new_domain=$2
        a2dissite "$old_domain.conf"
        cp "/etc/apache2/sites-available/${old_domain}.conf" "/etc/apache2/sites-available/${new_domain}.conf"
        sudo sed -i \
                -e "s/ServerName\s\+${old_domain}/ServerName ${new_domain}/" \
                -e "s/ServerAlias\s\+www.${old_domain}/ServerAlias www.${new_domain}/" \
                -e "s|/home/\([^/]\+\)/${old_domain}|/home/\1/${new_domain}|g" \
                -e "s|/var/log/apache2/\([^/]\+\)/${old_domain}/|/var/log/apache2/\1/${new_domain}/|g" \
                "/etc/apache2/sites-available/${new_domain}.conf"
        if [[ $? -eq 0 ]]; then
                echo "XÓA FILE CẤU HÌNH CŨ"
                rm "/etc/apache2/sites-available/${old_domain}.conf"
        else
                echo "THAY ĐỔI CẤU HÌNH THẤT BẠI VUI LÒNG KIỂM TRA CÁC BƯỚC TRƯỚC ĐÓ"
                exit
        fi
        account=$(grep "DocumentRoot" "/etc/apache2/sites-available/${new_domain}.conf" | cut -d'/' -f3)
        echo $account
        mv /home/${account}/$old_domain /home/${account}/$new_domain
        if [[ $? -eq 0 ]]; then
                echo "Đã thay đổi đường dẫn thư mục log"
        else
                echo "Thay đổi tên đường dẫn thư mục log thất bại"
        fi
        mv /var/log/apache2/${account}/$old_domain /var/log/apache2/${account}/$new_domain
        if [[ $? -eq 0 ]]; then
                echo "Đã thay đổi đường dẫn thư mục log"
        else
                echo "Thay đổi tên đường dẫn thư mục log thất bại"
        fi
        echo "ENABLE SITE ${new_domain}"
        a2ensite ${new_domain}.conf
        if [[ -f "/etc/apache2/sites-available/${old_domain}-le-ssl.conf" ]]; then
                rm -f "/etc/apache2/sites-available/${old_domain}-le-ssl.conf"
        fi
        systemctl reload apache2.service
}
main(){
        local domain1 domain2 php_version
while true; do
        echo "=========================================================="
        echo "          ĐIỀU CHỈNH CẤU HÌNH VHOST "
        echo "=========================================================="
        echo -e "\n1) THAY ĐỔI PHIÊN BẢN PHP "
        echo "2) THAY ĐỔI SERVER CỦA CẤU HÌNH VHOST"
        echo "3) RESET PASSWORD DATABASE"
        echo "4) THOÁT....."
        read -p "LỰA CHỌN: " choice
        case "$choice" in
                1)
                        read -p  "NHẬP WEBSITE MÀ BẠN MUỐN THAY ĐỔI PHIÊN BẢN PHP: " domain1
                        if  ./check_domain_exist.sh $domain1; then
                                read -p "NHẬP PHIÊN BẢN PHP MÀ BẠN MUỐN THAY ĐỔI CHO WEBSITE [7.1|7.2|7.3|7.4]: " php_version
                                # còn bổ sung phần check php hiện có và 
                                change_php_version $domain1 $php_version
                        else
                                echo "DOMAIN KHÔNG TỒN TẠI VUI LÒNG THỬ LẠI"

                        fi
                        ;;
                2)
                        read -p "TÊN MIỀN CỦA WEBSITE HIỆN TẠI CỦA BẠN LÀ GÌ: " domain1
                        if  ./check_domain_exist.sh $domain1; then
                                read -p "TÊN MIỀN MÀ BẠN MUỐN THAY ĐỔI LÀ GÌ: " domain2
                                if ! ./check_domain_exist.sh $domain2; then
                                        change_domain $domain1 $domain2
                                        echo "THAY ĐỔI TÊN MIỀN TRONG FILE CONFIG THÀNH CÔNG"
                                else
                                        echo "TÊN MIỀN MÀ BẠN MUỐN THAY ĐỔI HIỆN TẠI ĐÃ TỒN TẠI TRÊN SERVER VUI LÒNG THỬ LẠI VỚI 1 TÊN MIỀN KHÁC"
                                fi
                        else
                                echo "TÊN MIỀN CỦA BẠN HIỆN TẠI KHÔNG CÓ VUI LÒNG KIỂM TRA LẠI"
                        fi
                        ;;
                3)
                        # reset pass db
                        ;;
                4)
                        echo "THOÁT CHƯƠNG TRÌNH HIỆN TẠI"
                        exit
                        ;;
                *)
                        echo "LỰA CHỌN KHÔNG HỢP LỆ VUI LÒNG THỬ LẠI"
                        ;;
        esac
done
}
main


