#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

while true; do 
	clear
	echo -e "${GREEN}=============================================="
	echo -e "	  💻 CHƯƠNG TRÌNH QUẢN LÝ VIRTUAL HOST "
	echo -e "==============================================${RESET}"

	echo -e "📋 CHỌN CHỨC NĂNG:"
	echo -e "1) 🌐 ${YELLOW}Tạo Virtual Host${RESET}"
	echo -e "2) 📄 ${YELLOW}Liệt kê các Virtual Host${RESET}"
	echo -e "3) ❌ ${YELLOW}Xóa Virtual Host${RESET}"
	echo -e "4) ✏️  ${YELLOW}Chỉnh sửa Virtual Host${RESET}"
	echo -e "5) 🧰 ${YELLOW}Tool hỗ trợ${RESET}"
	echo -e "6) 🚪 ${YELLOW}Thoát${RESET}"
	echo "---------------------------------------"

	read -p "👉 Nhập lựa chọn của bạn: " choice
	case "$choice" in 
		1)
			bash ./create_vhost.sh
			read -p "🔁 Nhấn Enter để quay lại menu chính..."
			;;
		2)
			bash ./list_vhost.sh
			read -p "🔁 Nhấn Enter để quay lại menu chính..."
			;;
		3)
			bash ./remove_vhost.sh
			read -p "🔁 Nhấn Enter để quay lại menu chính..."
			;;
		4)
			bash ./edit_vhost.sh
			read -p "🔁 Nhấn Enter để quay lại menu chính..."
			;;
		5)
			bash ./tool.sh
			read -p "🔁 Nhấn Enter để quay lại menu chính..."
			;;
		6)
			echo -e "${RED}🚪 Thoát chương trình quản lý Virtual Host...${RESET}"
			exit
			;;
		*)
			echo -e "${RED}⚠️  Lựa chọn không hợp lệ! Vui lòng thử lại.${RESET}"
			sleep 1
			;;
	esac 
done 
