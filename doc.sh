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

# Ambil jumlah CPU core
CPU_CORES=$(nproc)

# Ambil IP VPS (bukan localhost)
VPS_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "🪟 Pilih versi Windows:"
cat <<EOF
 Value   | Version Name
---------|---------------------------
 11      | Windows 11 Pro
 11l     | Windows 11 LTSC
 11e     | Windows 11 Enterprise
 10      | Windows 10 Pro
 10l     | Windows 10 LTSC
 10e     | Windows 10 Enterprise
 8e      | Windows 8.1 Enterprise
 7u      | Windows 7 Ultimate
 vu      | Windows Vista Ultimate
 xp      | Windows XP Professional
 2k      | Windows 2000 Professional
 2025    | Windows Server 2025
 2022    | Windows Server 2022
 2019    | Windows Server 2019
 2016    | Windows Server 2016
 2012    | Windows Server 2012
 2008    | Windows Server 2008
 2003    | Windows Server 2003
EOF

read -p "Masukkan kode versi (default: 11): " VERSION
VERSION=${VERSION:-11}

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
  --name ${VERSION} \\
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

# Buat konfigurasi supervisor
tee /etc/supervisor/conf.d/windows-vm.conf > /dev/null <<EOF
[program:windows-vm]
command=/usr/local/bin/run-windows.sh
autostart=true
autorestart=true
stderr_logfile=/var/log/windows-vm.err.log
stdout_logfile=/var/log/windows-vm.out.log
EOF

# Reload Supervisor
supervisorctl reread
supervisorctl update
rm -rf *.sh
echo ""
echo "✅ Windows VM telah dijalankan di background."
echo "🌐 Web Viewer: http://${VPS_IP}:${WEB_PORT}"
echo "🖥️  RDP: ${VPS_IP}:${RDP_PORT}"
echo "🔁 Service aktif: Supervisor (windows-vm)"
echo "📂 Penyimpanan VM: /root/docker-windows-vm/windows"
