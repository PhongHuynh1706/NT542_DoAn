# 🔐 NGINX CIS Hardening & Security Validation

> **Môn học:** NT542 - Lập trình kịch bản tự động hoá cho quản trị và bảo mật mạng

---

## 🛠️ Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Web Server | NGINX |
| Tự động hoá | Ansible |
| Script kiểm tra | Bash |
| TLS / SSL | OpenSSL |

---

## 📁 Cấu trúc thư mục

```text
NT542_DOAN/
├── checking/
│   ├── checking_part4.sh
│   └── checking_part5.sh
│
├── deploy/
│   ├── deploy_part4.yml
│   └── deploy_part5.yml
│
├── templates/
│   ├── snippets/
│   │   ├── proxy_mtls.conf.j2
│   │   ├── security.conf.j2
│   │   └── ssl.conf.j2
│   │
│   ├── backend_mtls_8443.j2
│   ├── global_nginx.j2
│   ├── http_redirect_80.j2
│   └── https_frontend_443.j2
│
├── unmerge_parts/
│   └── part4.j2
│
├── vars/
│   └── cert_path.yml
│
├── .gitattributes
├── .gitignore
├── inventory.ini
└── README.md
```

---

## ⚙️ Cài đặt môi trường

### Yêu cầu

- Ubuntu Server 20.04+
- NGINX
- Ansible
- OpenSSL
- ApacheBench (`ab`)
- netcat (`nc`)
- curl

---

## 📦 Cài đặt dependency

```bash
sudo apt update

sudo apt install -y \
ansible \
nginx \
apache2-utils \
curl \
openssl \
netcat-openbsd
```

---

## 🚀 Triển khai cấu hình bằng Ansible

### Triển khai TLS / SSL Hardening (Part 4)

```bash
ansible-playbook -i inventory.ini deploy/deploy_part4.yml
```

### Triển khai NGINX Hardening (Part 5)

```bash
ansible-playbook -i inventory.ini deploy/deploy_part5.yml
```

---

## 🔎 Kiểm tra cấu hình bảo mật

### Phân quyền script

```bash
chmod +x checking/checking_part4.sh
chmod +x checking/checking_part5.sh
```

---

### Kiểm tra TLS / SSL Security

```bash
cd checking

sudo ./checking_part4.sh
```

---

### Kiểm tra NGINX Hardening

```bash
cd checking

sudo ./checking_part5.sh
```

---

## 🛡️ Nội dung kiểm tra

### Part 4 — TLS / SSL Security

- TLS 1.2 / TLS 1.3
- Cipher Suite
- Session Resumption
- HSTS
- OCSP Stapling
- SSL Session Cache
- SSL Session Timeout

---

### Part 5 — NGINX Hardening

#### 5.1 Access Control

- Giới hạn IP truy cập
- Giới hạn HTTP Method

#### 5.2 Resource Protection

- Slowloris Protection
- Max Body Size
- Keepalive Requests
- Connection Limiting
- Request Rate Limiting

#### 5.3 Client-Side Security

- MIME Sniffing Protection
- Content Security Policy (CSP)
- Referrer Policy
- Clickjacking Protection

---

## 🧪 Kiểm tra nhanh

### Kiểm tra syntax nginx

```bash
sudo nginx -t
```

---

### Reload nginx

```bash
sudo systemctl reload nginx
```

---

### Kiểm tra trạng thái nginx

```bash
sudo systemctl status nginx
```

---

### Xem toàn bộ config nginx

```bash
sudo nginx -T
```

---

## ⚠️ Một số lỗi thường gặp

### Lỗi CRLF khi chạy shell script

```text
/bin/bash^M: bad interpreter
```

### Khắc phục

```bash
dos2unix checking/*.sh
```

hoặc:

```bash
git config --global core.autocrlf input
```
