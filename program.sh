#!/bin/bash
# Reset về mặc định
RESET='\033[0m'
# Màu chữ cơ bản
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
# Màu đậm
BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
while true; do 
	clear
	echo -e  "${GREEN}=============================================="
	echo -e "	  CHƯƠNG TRÌNH QUẢN LÝ VHOST "
	echo -e "==============================================${RESET}"

	echo " 		CHỌN CHỨC NĂNG"
	echo -e "1) ${YELLOW}Tạo Virtual host${RESET}"
	echo -e "2) ${YELLOW}Liệt kê các Virtual Host${RESET}"
	echo -e "3) ${YELLOW}Xóa Virtual Host${RESET}"
	echo -e "4) ${YELLOW}Chỉnh sửa Virtual Host${RESET}"
	echo -e "5) ${YELLOW}Tool${RESET}"
	echo -e "6) ${YELLOW}Thoát${RESET}"
	echo "---------------------------------------"
	read -p "Nhập lựa chọn của bạn: " choice
	case "$choice" in 
		1)
			bash ./create_vhost.sh
			read -p "Nhấn Enter để quay lại menu chính..."
			;;
		2)
			bash ./list_vhost.sh
			read -p "Nhấn Enter để quay lại menu chính..."
			;;
		3)
			bash ./remove_vhost.sh
			read -p "Nhấn Enter để quay lại menu chính..."
			;;
		4)
			bash ./edit_vhost.sh
			read -p "Nhấn Enter để quay lại menu chính..."
			;;
		5)
			bash ./tool.sh
			read -p "Nhấn Enter để quay lại menu chính..."
			;;
		6)
			echo "-----------THOÁT CHƯƠNG TRÌNH-----------"
			exit
			;;
		*)
			echo -e "${RED}Lựa chọn không hợp lệ vui lòng thử lại!!${RESET}"
			sleep 1
			;;
	esac 

done 
