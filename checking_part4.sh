#!/bin/bash

# =========================================================
# CIS NGINX BENCHMARK - SECTION 4 VALIDATION
# TLS / SSL CONFIGURATION
# =========================================================

CA_CERT="/home/ph/NT542/MyCA/my-ca.crt"
CLIENT_CERT="/home/ph/NT542/MyCA/nginx-client.crt"
CLIENT_KEY="/home/ph/NT542/MyCA/nginx-client.key"

PASS=0
FAIL=0

pass() {
    echo "[PASS] $1"
    PASS=$((PASS+1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL+1))
}

section() {
    echo
    echo "================================================="
    echo "$1"
    echo "================================================="
}

# =========================================================
# 4.1.1 HTTP -> HTTPS REDIRECT
# =========================================================

section "4.1.1 HTTP TO HTTPS REDIRECTION"

HTTP_RESPONSE=$(curl -s -I http://localhost | head -n 1)

if echo "$HTTP_RESPONSE" | grep -q "301"; then
    pass "HTTP redirected to HTTPS"
else
    fail "HTTP redirection not configured"
fi

# =========================================================
# 4.1.2 TRUSTED CERTIFICATE
# =========================================================

section "4.1.2 TRUSTED CERTIFICATE VALIDATION"

TLS_VERIFY=$(echo | openssl s_client \
-connect localhost:443 \
-CAfile "$CA_CERT" 2>/dev/null)

if echo "$TLS_VERIFY" | grep -q "Verify return code: 0"; then
    pass "Certificate trust chain valid"
else
    fail "Certificate validation failed"
fi

# =========================================================
# 4.1.3 PRIVATE KEY PERMISSION
# =========================================================

section "4.1.3 PRIVATE KEY PERMISSIONS"

KEY_FILES=$(find /home/ph/NT542/MyCA -name "*.key")

for key in $KEY_FILES
do
    PERM=$(stat -c "%a" "$key")

    if [ "$PERM" = "400" ] || [ "$PERM" = "600" ]; then
        pass "$key permissions restricted ($PERM)"
    else
        fail "$key permissions too permissive ($PERM)"
    fi
done

# =========================================================
# 4.1.4 TLS 1.3 ONLY
# =========================================================

section "4.1.4 TLS 1.3 VALIDATION"

if nginx -T 2>/dev/null | grep -E '^\s*ssl_protocols TLSv1.3;' >/dev/null; then
    pass "Only TLSv1.3 enabled"
else
    fail "TLSv1.3-only configuration missing"
fi

# =========================================================
# 4.1.5 WEAK CIPHER DISABLED
# =========================================================

section "4.1.5 WEAK CIPHER VALIDATION"

if nginx -T 2>/dev/null | grep -E '^\s*ssl_prefer_server_ciphers off;' >/dev/null; then
    pass "ssl_prefer_server_ciphers set to off"
else
    fail "ssl_prefer_server_ciphers not configured"
fi

# =========================================================
# 4.1.9 mTLS CLIENT AUTHENTICATION
# =========================================================

section "4.1.9 mTLS CLIENT AUTHENTICATION"

BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
--cert "$CLIENT_CERT" \
--key "$CLIENT_KEY" \
--cacert "$CA_CERT" \
https://localhost:8443)

if [ "$BACKEND_CODE" = "200" ]; then
    pass "Mutual TLS authentication successful"
else
    fail "Mutual TLS authentication failed"
fi

# =========================================================
# 4.1.10 UPSTREAM TRUST CHAIN
# =========================================================

section "4.1.10 UPSTREAM TRUST VALIDATION"

if nginx -T 2>/dev/null | grep -q "proxy_ssl_trusted_certificate"; then
    pass "proxy_ssl_trusted_certificate configured"
else
    fail "proxy_ssl_trusted_certificate missing"
fi

if nginx -T 2>/dev/null | grep -q "proxy_ssl_verify on"; then
    pass "proxy_ssl_verify enabled"
else
    fail "proxy_ssl_verify disabled"
fi

# =========================================================
# 4.1.11 SESSION RESUMPTION
# =========================================================

section "4.1.11 SESSION RESUMPTION"

if nginx -T 2>/dev/null | grep -iq "ssl_session_tickets on"; then
    pass "TLS session tickets enabled"
else
    fail "TLS session tickets disabled"
fi

# =========================================================
# 4.1.12 HTTP/2 + HTTP/3
# =========================================================

section "4.1.12 HTTP/2 AND HTTP/3"

if curl -s -I \
--http2 \
--cacert "$CA_CERT" \
https://localhost | grep -q "HTTP/2"; then

    pass "HTTP/2 operational"
else
    fail "HTTP/2 not operational"
fi

if nginx -T 2>/dev/null | grep -q "listen 443 quic reuseport"; then
    pass "HTTP/3 QUIC listener configured"
else
    fail "HTTP/3 QUIC listener missing"
fi

if curl -s -I \
--cacert "$CA_CERT" \
https://localhost | grep -iq "alt-svc"; then

    pass "Alt-Svc header present"
else
    fail "Alt-Svc header missing"
fi

# =========================================================
# FINAL RESULT
# =========================================================

section "FINAL RESULT"

echo "PASSED : $PASS"
echo "FAILED : $FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo
    echo "[RESULT] CIS SECTION 4 COMPLIANT"
    exit 0
else
    echo
    echo "[RESULT] CIS SECTION 4 NON-COMPLIANT"
    exit 1
fi