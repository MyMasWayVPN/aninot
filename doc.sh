#!/bin/bash

set -e

# Pastikan script dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Jalankan script ini sebagai root: sudo $0"
  exit 1
fi

echo "🔧 Menginstall dependensi..."
apt update
apt install -y docker.io supervisor curl

# Aktifkan Docker & Supervisor
systemctl enable --now docker
systemctl enable --now supervisor

# Hitung sumber daya
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2}')
TOTAL_DISK=$(df / --output=size | tail -1)

RAM_SIZE=$((TOTAL_RAM * 90 / 100))G
DISK_SIZE=$((TOTAL_DISK * 90 / 100 / 1024000))G

CPU_CORES=$(nproc)
VPS_IP=$(hostname -I | awk '{print $1}')

# --- MENU WINDOWS VERSION ---
echo ""
echo "--- MENU WINDOWS VERSION ---"
echo "Pilih versi Windows:"
echo "01 | 1)  Windows 11 Pro (4.8GB)"
echo "02 | 2)  Windows 11 LTSC (4.7GB)"
echo "03 | 3)  Windows 11 Enterprise (4.8GB)"
echo "04 | 4)  Windows 10 Pro (3.5GB)"
echo "05 | 5)  Windows 10 LTSC (4.1GB)"
echo "06 | 6)  Windows 10 Enterprise (3.4GB)"
echo "07 | 7)  Windows 8.1 Enterprise (3.8GB)"
echo "08 | 8)  Windows 7 Ultimate (2.9GB)"
echo "09 | 9)  Windows Vista Ultimate (2.5GB)"
echo "10 |10)  Windows XP Professional (1.6GB)"
echo "11 |11)  Windows 2000 Professional (0.7GB)"
echo "12 |12)  Windows Server 2025 (5.1GB)"
echo "13 |13)  Windows Server 2022 (5.0GB)"
echo "14 |14)  Windows Server 2019 (4.6GB)"
echo "15 |15)  Windows Server 2016 (4.4GB)"
echo "16 |16)  Windows Server 2012 (4.1GB)"
echo "17 |17)  Windows Server 2008 (3.5GB)"
echo "18 |18)  Windows Server 2003 (2.3GB)"

read -p "Masukkan nomor (default 1): " win_choice

case "$win_choice" in
  2|02) VERSION="11l" ;;
  3|03) VERSION="11e" ;;
  4|04) VERSION="10" ;;
  5|05) VERSION="10l" ;;
  6|06) VERSION="10e" ;;
  7|07) VERSION="8e" ;;
  8|08) VERSION="7u" ;;
  9|09) VERSION="vu" ;;
 10) VERSION="xp" ;;
 11) VERSION="2k" ;;
 12) VERSION="2025" ;;
 13) VERSION="2022" ;;
 14) VERSION="2019" ;;
 15) VERSION="2016" ;;
 16) VERSION="2012" ;;
 17) VERSION="2008" ;;
 18) VERSION="2003" ;;
 1|01|"") VERSION="11" ;;  # Default ke Windows 11 Pro
  *) VERSION="11" ;;       # Jika input tidak valid
esac


read -p "Port Web Viewer (default: 8006): " WEB_PORT
WEB_PORT=${WEB_PORT:-8006}

read -p "Port RDP (default: 3390): " RDP_PORT
RDP_PORT=${RDP_PORT:-3390}

read -p "Username (default: docker): " USERNAME
USERNAME=${USERNAME:-docker}

read -sp "Password (default: admin): " PASSWORD
echo
PASSWORD=${PASSWORD:-admin}

# Simpan script run-windows.sh
cat > /usr/local/bin/run-windows.sh <<EOF
#!/bin/bash
docker run --rm \\
  --name windows \\
  -p ${WEB_PORT}:8006 \\
  -p ${RDP_PORT}:3389/tcp \\
  -p ${RDP_PORT}:3389/udp \\
  --device=/dev/kvm \\
  --device=/dev/net/tun \\
  --cap-add NET_ADMIN \\
  -e VERSION="${VERSION}" \\
  -e USERNAME="${USERNAME}" \\
  -e PASSWORD="${PASSWORD}" \\
  -e DISK_SIZE="${DISK_SIZE}" \\
  -e RAM_SIZE="${RAM_SIZE}" \\
  -e CPU_CORES="${CPU_CORES}" \\
  -v "/root/docker-windows-vm/windows:/storage" \\
  --stop-timeout 120 \\
  dockurr/windows
EOF

chmod +x /usr/local/bin/run-windows.sh

tee /etc/supervisor/conf.d/windows-vm.conf > /dev/null <<EOF
[program:windows-vm]
command=/usr/local/bin/run-windows.sh
autostart=true
autorestart=true
stderr_logfile=/var/log/windows-vm.err.log
stdout_logfile=/var/log/windows-vm.out.log
EOF

supervisorctl reread
supervisorctl update
rm -rf *.sh

echo ""
echo "✅ Windows VM telah dijalankan di background."
echo "🌐 Web Viewer: http://${VPS_IP}:${WEB_PORT}"
echo "🖥️  RDP: ${VPS_IP}:${RDP_PORT}"
echo "🔁 Service aktif: Supervisor (windows-vm)"
echo "📂 Penyimpanan VM: /root/docker-windows-vm/windows"
