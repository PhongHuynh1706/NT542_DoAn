#!/bin/bash
TARGET="http://127.0.0.1"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}====================================================${NC}"
echo -e "${YELLOW} BẮT ĐẦU CHIẾN DỊCH TẤN CÔNG & KIỂM TRA BẢO MẬT NGINX${NC}"
echo -e "${YELLOW}====================================================${NC}\n"

dd if=/dev/zero of=test_3mb.dat bs=1M count=3 >/dev/null 2>&1
sudo dd if=/dev/zero of=/var/www/html/bigfile.dat bs=1M count=10 >/dev/null 2>&1

echo -e "[*] Đang test Phần 5.2: Giới hạn tài nguyên..."

# 1. Test 5.2.1: Ngâm kết nối (Slowloris)
(printf "GET / HTTP/1.1\r\nHost: 127.0.0.1\r\n"; sleep 12) | nc 127.0.0.1 80 > slow_test.log 2>&1
# BẢN VÁ: Soi thêm log của NGINX để làm bằng chứng thay vì chỉ dựa vào nc
if grep -q "408" slow_test.log || tail -n 5 /var/log/nginx/access.json | grep -q "408"; then
    echo -e " 🛡️ 5.2.1 Timeout (Chống Slowloris) : ${GREEN}[PASS] Đã chặn (Ghi nhận mã 408)${NC}"
else
    echo -e " ❌ 5.2.1 Timeout (Chống Slowloris) : ${RED}[FAIL] Server bị ngâm kết nối${NC}"
fi

# 2. Test 5.2.2: Bơm file khổng lồ
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -F "file=@test_3mb.dat" $TARGET/)
if [ "$HTTP_CODE" -eq 413 ]; then
    echo -e " 🛡️ 5.2.2 Max Body Size (Chống tràn): ${GREEN}[PASS] Đã trả về 413${NC}"
else
    echo -e " ❌ 5.2.2 Max Body Size (Chống tràn): ${RED}[FAIL] Đã nhận file rác (Mã $HTTP_CODE)${NC}"
fi

# 3. Test 5.2.3: Bòn rút Keep-Alive
KA_REQ=$(ab -n 20 -c 1 -k $TARGET/ 2>/dev/null | grep "Keep-Alive requests:" | awk '{print $3}')
if [ "$KA_REQ" == "16" ]; then
    echo -e " 🛡️ 5.2.3 Keep-alive (Chống ngậm ống): ${GREEN}[PASS] Ép ngắt sau 5 request${NC}"
else
    echo -e " ❌ 5.2.3 Keep-alive (Chống ngậm ống): ${RED}[FAIL] Cho phép $KA_REQ kết nối liên tục${NC}"
fi

# 4. Test 5.2.4: Bủa vây kết nối
FAIL_CONN=$(ab -n 50 -c 10 $TARGET/bigfile.dat 2>/dev/null | grep "Non-2xx responses:" | awk '{print $3}')
if [ -n "$FAIL_CONN" ]; then
    echo -e " 🛡️ 5.2.4 Limit Conn (Chống mở Tab) : ${GREEN}[PASS] Đã chặn $FAIL_CONN truy cập${NC}"
else
    echo -e " ❌ 5.2.4 Limit Conn (Chống mở Tab) : ${RED}[FAIL] Cho qua mọi kết nối đồng thời${NC}"
fi

# 5. Test 5.2.5: Spam Brute-force
FAIL_REQ=$(ab -n 200 -c 20 $TARGET/login 2>/dev/null | grep "Non-2xx responses:" | awk '{print $3}')
if [ -n "$FAIL_REQ" ]; then
    echo -e " 🛡️ 5.2.5 Limit Req (Chống Spam)    : ${GREEN}[PASS] Đã chặn $FAIL_REQ truy cập Spam${NC}"
else
    echo -e " ❌ 5.2.5 Limit Req (Chống Spam)    : ${RED}[FAIL] Cho qua toàn bộ 200 Spam${NC}"
fi

echo ""
# ---------------------------------------------------------
# PHẦN 5.3: TẤN CÔNG BẢO MẬT TRÌNH DUYỆT (MÔ PHỎNG THỰC TẾ)
# ---------------------------------------------------------
echo -e "[*] Đang test Phần 5.3: Kịch bản tấn công Client-Side..."

# --- BƯỚC 1: HACKER CHUẨN BỊ VŨ KHÍ (Tạo file độc hại) ---
# Mô phỏng Hacker chèn file text chứa mã JavaScript (MIME Sniffing)
sudo bash -c 'echo "alert(\"Hacker MIME Sniffing!\");" > /var/www/html/attack.txt'
# Mô phỏng Hacker chèn file HTML chứa mã độc ẩn (Inline XSS)
sudo bash -c 'echo "<script>alert(\"XSS Attack!\");</script>" > /var/www/html/xss_test.html'

# --- BƯỚC 2: TIẾN HÀNH TẤN CÔNG & KIỂM TRA KHIÊN ---

# 1. Test 5.3.1: MIME Sniffing Attack
# Hỏi: Khi tải file text độc hại này, NGINX có dán nhãn cấm chạy (nosniff) không?
HEADER_531=$(curl -s -I $TARGET/attack.txt)
if echo "$HEADER_531" | grep -qi "X-Content-Type-Options: nosniff"; then
    echo -e " 🛡️ 5.3.1 Chống MIME Sniffing   : ${GREEN}[PASS] Đã kẹp 'nosniff' vào file attack.txt${NC}"
else
    echo -e " ❌ 5.3.1 Chống MIME Sniffing   : ${RED}[FAIL] Trống (Trình duyệt sẽ bị lừa chạy file txt)${NC}"
fi

# 2. Test 5.2.2: Bơm file khổng lồ
HTTP_CODE=$(curl -k -L -s -o /dev/null \
-w "%{http_code}" \
-F "file=@test_3mb.dat" \
https://localhost/)
if [ "$HTTP_CODE" -eq 413 ]; then
    echo -e " 🛡️ 5.2.2 Max Body Size (Chống tràn): ${GREEN}[PASS] Đã trả về 413${NC}"
else
    echo -e " ❌ 5.2.2 Max Body Size (Chống tràn): ${RED}[FAIL] Đã nhận file rác (Mã $HTTP_CODE)${NC}"
fi

# 3. Test 5.2.3: Bòn rút Keep-Alive
if sudo nginx -T 2>/dev/null | grep -Eq "keepalive_requests[[:space:]]+5;"; then
    echo -e " 🛡️ 5.2.3 Keep-alive (Chống ngậm ống): ${GREEN}[PASS] Đã giới hạn keepalive_requests = 5${NC}"
else
    echo -e " ❌ 5.2.3 Keep-alive (Chống ngậm ống): ${RED}[FAIL] Chưa giới hạn keepalive_requests${NC}"
fi


# --- BƯỚC 3: DỌN DẸP CHIẾN TRƯỜNG ---
sudo rm -f /var/www/html/attack.txt /var/www/html/xss_test.html

# Dọn dẹp rác của Phần 5.2
rm -f test_3mb.dat slow_test.log
echo -e "\n${YELLOW}====================================================${NC}"
echo -e "${YELLOW} KIỂM TRA HOÀN TẤT!${NC}"
echo -e "${YELLOW}====================================================${NC}"