#!/bin/bash

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
        echo "❌ Kết nối thất bại. Kiểm tra lại ZONE_ID, EMAIL hoặc API_KEY."
        return 1
    fi
}
list_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3
        curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records \
                -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
                -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
                 | jq -r '.result[] | 
                "ID bảng ghi: \(.id)\nType: \(.type)\nName: \(.name)\nContent: \(.content)\nProxied: \(.proxied)\n---"'
}
create_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    read -p "Tên bản ghi (ví dụ: abc.domain.com): " NAME
    read -p "Loại bản ghi (A, CNAME, etc): " TYPE
    read -p "Giá trị bản ghi (IP/domain): " VALUE
    read -p "Có proxy qua Cloudflare? (true/false): " PROXY

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
    read -p "Nhập ID của DNS record cần xoá: " DNS_RECORD_ID
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H 'Content-Type: application/json' | jq '.success, .errors'
}

update_record(){
    local ZONE_ID=$1
    local CLOUDFLARE_EMAIL=$2
    local CLOUDFLARE_API_KEY=$3

    read -p "Nhập ID của DNS record cần sửa: " DNS_RECORD_ID
    read -p "Tên mới: " NAME
    read -p "Loại bản ghi (A, CNAME...): " TYPE
    read -p "Nội dung mới (IP/domain): " CONTENT
    read -p "Proxy qua Cloudflare? (true/false): " PROXIED

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
    echo "==============================="
    echo " NHẬP THÔNG TIN KẾT NỐI CLOUDFLARE"
    echo "==============================="

    read -p "Email Cloudflare: " CLOUDFLARE_EMAIL
    read -p "API Key         : " CLOUDFLARE_API_KEY
    read -p "Zone ID         : " ZONE_ID
    echo "🔄 Đang kiểm tra kết nối tới Cloudflare..."
    if ! check_connection "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"; then
        echo "Thông tin của bạn cung cấp hiện chưa kết nối được với Cloudflare. Bạn vui lòng kiểm tra lại nhé"
        exit 1
    fi
    echo "✅ Kết nối thành công!"
    echo ""
    while true; do
        echo "==============================="
        echo "  QUẢN LÝ DNS RECORD CLOUDFLARE"
        echo "==============================="
        echo "1) In danh sách bản ghi DNS"
        echo "2) Tạo bản ghi DNS"
        echo "3) Xoá bản ghi DNS"
        echo "4) Sửa bản ghi DNS"
        echo "0) Thoát"
        echo "-------------------------------"
        read -p "Nhập lựa chọn (0-3): " choice
        case "$choice" in
            1)
                    list_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"
                    ;;
            2)
                create_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"
                ;;
            3)
                delete_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"
                ;;
            4)
                update_record "$ZONE_ID" "$CLOUDFLARE_EMAIL" "$CLOUDFLARE_API_KEY"
                ;;
            0)
                echo "👋 Thoát chương trình."
                break
                ;;
            *)
                echo "❌ Lựa chọn không hợp lệ! Vui lòng nhập từ 0 đến 3."
                ;;
        esac
        echo
    done
}
main





