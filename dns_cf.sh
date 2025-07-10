#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

check_connection() {
    local ZONE_ID="$1"
    local EMAIL="$2"
    local API_KEY="$3"

    response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
        -H "X-Auth-Email: ${EMAIL}" \
        -H "X-Auth-Key: ${API_KEY}" \
        -H "Content-Type: application/json")

    if echo "$response" | grep -q '"success":true'; then
        return 0
    else
        echo -e "${RED}❌ Kết nối thất bại. Kiểm tra lại ZONE_ID, EMAIL hoặc API_KEY.${RESET}"
        return 1
    fi
}

list_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    echo -e "${BLUE}📋 Danh sách bản ghi DNS:${RESET}"
    curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json" | jq -r '
        .result[] |
        "🔹 ID: \(.id)\n🔹 Type: \(.type)\n🔹 Name: \(.name)\n🔹 Content: \(.content)\n🔹 Proxied: \(.proxied)\n---"
    '
}

create_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    echo -e "${YELLOW}➕ TẠO BẢN GHI MỚI${RESET}"
    read -p "🔤 Tên bản ghi (VD: abc.domain.com): " NAME
    read -p "📛 Loại bản ghi (A, CNAME,...): " TYPE
    read -p "📥 Giá trị bản ghi (IP/domain): " VALUE
    read -p "🌐 Có proxy qua Cloudflare? (true/false): " PROXY

    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
        -H 'Content-Type: application/json' \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -d "{
            \"type\": \"$TYPE\",
            \"name\": \"$NAME\",
            \"content\": \"$VALUE\",
            \"ttl\": 3600,
            \"proxied\": $PROXY
        }" | jq '.success, .errors'
}

delete_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    echo -e "${RED}🗑️ XOÁ BẢN GHI DNS${RESET}"
    read -p "📄 Nhập ID của bản ghi DNS cần xoá: " DNS_RECORD_ID

    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H 'Content-Type: application/json' | jq '.success, .errors'
}

update_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    echo -e "${BLUE}✏️ SỬA BẢN GHI DNS${RESET}"
    read -p "📄 Nhập ID của bản ghi DNS: " DNS_RECORD_ID
    read -p "🔤 Tên mới: " NAME
    read -p "📛 Loại bản ghi (A, CNAME...): " TYPE
    read -p "📥 Nội dung mới (IP/domain): " CONTENT
    read -p "🌐 Proxy qua Cloudflare? (true/false): " PROXIED

    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
        -H 'Content-Type: application/json' \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -d "{
            \"type\": \"$TYPE\",
            \"name\": \"$NAME\",
            \"content\": \"$CONTENT\",
            \"ttl\": 3600,
            \"proxied\": $PROXIED
        }" | jq '.success, .errors'
}

main() {
    echo -e "${GREEN}==============================="
    echo " NHẬP THÔNG TIN KẾT NỐI CLOUDFLARE"
    echo -e "===============================${RESET}"

    read -s -p "📧 Email Cloudflare     : " CLOUDFLARE_EMAIL
    read -s -p "🔑 API Key              : " CLOUDFLARE_API_KEY
    read -s -p "🌐 Zone ID              : " ZONE_ID

    echo -e "${BLUE}🔄 Đang kiểm tra kết nối tới Cloudflare...${RESET}"
    if ! check_connection "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"; then
        echo -e "${RED}❌ Không thể kết nối đến Cloudflare. Kiểm tra thông tin và thử lại.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}✅ Kết nối Cloudflare thành công!${RESET}\n"

    while true; do
        echo -e "${YELLOW}==============================="
        echo "  📡 QUẢN LÝ DNS RECORD CLOUDFLARE"
        echo -e "===============================${RESET}"
        echo -e "1) 📋 In danh sách bản ghi DNS"
        echo -e "2) ➕ Tạo bản ghi DNS mới"
        echo -e "3) 🗑️ Xoá bản ghi DNS"
        echo -e "4) ✏️ Sửa bản ghi DNS"
        echo -e "0) 🚪 Thoát"
        echo "---------------------------------------"
        read -p "👉 Nhập lựa chọn (0-4): " choice

        case "$choice" in
            1) list_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY" ;;
            2) create_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY" ;;
            3) delete_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY" ;;
            4) update_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY" ;;
            0)
                echo -e "${GREEN}👋 Thoát chương trình. Hẹn gặp lại!${RESET}"
                break
                ;;
            *)
                echo -e "${RED}❌ Lựa chọn không hợp lệ. Vui lòng nhập từ 0 đến 4.${RESET}"
                ;;
        esac
        echo
    done
}
main
