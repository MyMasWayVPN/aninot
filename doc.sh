#!/bin/bash

echo "=== Setup Windows VM dengan Docker Compose ==="

# Minta input dari pengguna
read -p "Masukkan port untuk RDP (default: 3390): " RDP_PORT
RDP_PORT=${RDP_PORT:-3390}

read -p "Masukkan port untuk Web Viewer (default: 8006): " WEB_PORT
WEB_PORT=${WEB_PORT:-8006}

read -p "Masukkan username (default: docker): " USERNAME
USERNAME=${USERNAME:-docker}

read -sp "Masukkan password (default: admin): " PASSWORD
echo
PASSWORD=${PASSWORD:-admin}

read -p "Pilih versi Windows (default: 11): " VERSION
VERSION=${VERSION:-11}

read -p "Ukuran disk (default: 64G): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-64G}

read -p "Jumlah RAM (default: 4G): " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-4G}

read -p "Jumlah CPU core (default: 2): " CPU_CORES
CPU_CORES=${CPU_CORES:-2}

read -p "Direktori penyimpanan (default: ./windows): " STORAGE_DIR
STORAGE_DIR=${STORAGE_DIR:-./windows}

# Buat direktori penyimpanan jika belum ada
mkdir -p "$STORAGE_DIR"

# Tulis docker-compose.yml
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "$VERSION"
      USERNAME: "$USERNAME"
      PASSWORD: "$PASSWORD"
      DISK_SIZE: "$DISK_SIZE"
      RAM_SIZE: "$RAM_SIZE"
      CPU_CORES: "$CPU_CORES"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - ${WEB_PORT}:8006
      - ${RDP_PORT}:3389/tcp
      - ${RDP_PORT}:3389/udp
    volumes:
      - ${STORAGE_DIR}:/storage
    restart: always
    stop_grace_period: 2m
EOF

# Jalankan container
echo -e "\nMenjalankan container Windows VM..."
docker-compose up -d

echo -e "\n✅ Selesai!"
echo "Web Viewer: http://localhost:$WEB_PORT"
echo "RDP       : localhost:$RDP_PORT (user: $USERNAME, pass: $PASSWORD)"
