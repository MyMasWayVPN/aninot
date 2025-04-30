#!/bin/bash

set -e

echo "🚀 Menyiapkan sistem..."

# Install Docker jika belum ada
if ! command -v docker &>/dev/null; then
  echo "📦 Menginstal Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
fi

# Tambahkan user ke grup docker jika perlu
if ! groups $USER | grep -qw docker; then
  echo "👥 Menambahkan user '$USER' ke grup docker..."
  sudo usermod -aG docker $USER
  echo "🔁 Logout & login ulang mungkin diperlukan agar grup berlaku."
fi

mkdir -p ~/docker-windows-vm/windows
cd ~/docker-windows-vm

# Hitung RAM dan DISK
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2}')
TOTAL_DISK=$(df / --output=size | tail -1)

RAM_SIZE=$((TOTAL_RAM * 90 / 100))G
DISK_SIZE=$((TOTAL_DISK * 80 / 100 / 1024))G

echo ""
echo "📊 Sistem: ${TOTAL_RAM}GB RAM, $((TOTAL_DISK / 1024))GB DISK"
echo "📦 Dialokasikan: RAM=${RAM_SIZE}, DISK=${DISK_SIZE}"

# Menu versi Windows
echo ""
echo "Pilih versi Windows:"
cat <<EOF
 Value   | Version Name              | Size
---------|---------------------------|------
 11      | Windows 11 Pro            | 5.4G
 11l     | Windows 11 LTSC           | 4.7G
 11e     | Windows 11 Enterprise     | 4.0G
 10      | Windows 10 Pro            | 5.7G
 10l     | Windows 10 LTSC           | 4.6G
 10e     | Windows 10 Enterprise     | 5.2G
 8e      | Windows 8.1 Enterprise    | 3.7G
 7u      | Windows 7 Ultimate        | 3.1G
 vu      | Windows Vista Ultimate    | 3.0G
 xp      | Windows XP Professional   | 0.6G
 2k      | Windows 2000 Professional | 0.4G
 2025    | Windows Server 2025       | 5.6G
 2022    | Windows Server 2022       | 4.7G
 2019    | Windows Server 2019       | 5.3G
 2016    | Windows Server 2016       | 6.5G
 2012    | Windows Server 2012       | 4.3G
 2008    | Windows Server 2008       | 3.0G
 2003    | Windows Server 2003       | 0.6G
EOF

read -p "Masukkan kode versi (default: 11): " VERSION
VERSION=${VERSION:-11}

read -p "Port Web Viewer [default: 8006]: " WEB_PORT
WEB_PORT=${WEB_PORT:-8006}

read -p "Port RDP [default: 3390]: " RDP_PORT
RDP_PORT=${RDP_PORT:-3390}

read -p "Username [default: docker]: " USERNAME
USERNAME=${USERNAME:-docker}

read -sp "Password [default: admin]: " PASSWORD
echo
PASSWORD=${PASSWORD:-admin}

# Simpan file startup
cat > start-windows-vm.sh <<EOF
#!/bin/bash
docker run -d \\
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
  -v "\$PWD/windows:/storage" \\
  --stop-timeout 120 \\
  --memory="${RAM_SIZE}" \\
  --memory-swap="${RAM_SIZE}" \\
  dockurr/windows
EOF

chmod +x start-windows-vm.sh

# Buat systemd service
cat > /etc/systemd/system/docker-windows.service <<EOF
[Unit]
Description=Windows VM in Docker
Requires=docker.service
After=docker.service

[Service]
ExecStart=/home/$USER/docker-windows-vm/start-windows-vm.sh
ExecStop=/usr/bin/docker stop windows
Restart=always
User=$USER
WorkingDirectory=/home/$USER/docker-windows-vm
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF

# Aktifkan service
systemctl daemon-reload
systemctl enable docker-windows.service
systemctl start docker-windows.service

echo ""
echo "✅ Windows VM telah dijalankan!"
echo "🌐 Web Viewer: http://localhost:${WEB_PORT}"
echo "🖥️  RDP: localhost:${RDP_PORT}"
echo "👤 Login: ${USERNAME} / ${PASSWORD}"
echo "🔁 Service aktif: docker-windows.service"
