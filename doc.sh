#!/bin/bash

set -e

mkdir -p ~/docker-windows-vm/windows
cd ~/docker-windows-vm

# Hitung sumber daya
TOTAL_RAM=$(free -g | awk '/^Mem:/ {print $2}')
TOTAL_DISK=$(df / --output=size | tail -1)

RAM_SIZE=$((TOTAL_RAM * 90 / 100))G
DISK_SIZE=$((TOTAL_DISK * 80 / 100 / 1024))G

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

read -p "Jumlah CPU core (default: 2): " CPU_CORES
CPU_CORES=${CPU_CORES:-2}

# Simpan script run-windows.sh
cat > run-windows.sh <<EOF
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
  -e CPU_CORES="${CPU_CORES}" \\
  -v "\$PWD/windows:/storage" \\
  --stop-timeout 120 \\
  dockurr/windows
EOF

chmod +x run-windows.sh

# Buat systemd unit file
sudo tee /etc/systemd/system/docker-windows.service > /dev/null <<EOF
[Unit]
Description=Auto Start Windows VM Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/home/$USER/docker-windows-vm/run-windows.sh
ExecStop=/usr/bin/docker stop windows
User=$USER
WorkingDirectory=/home/$USER/docker-windows-vm
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF

# Enable dan jalankan service
sudo systemctl daemon-reload
sudo systemctl enable docker-windows.service
sudo systemctl start docker-windows.service

echo ""
echo "✅ Windows VM telah berjalan di background."
echo "🌐 Web Viewer: http://localhost:${WEB_PORT}"
echo "🖥️  RDP: localhost:${RDP_PORT}"
echo "🔁 Service aktif: docker-windows.service"
echo "📂 Penyimpanan VM: ~/docker-windows-vm/windows"
