#!/bin/bash

echo "=== Jalankan Windows VM dengan Docker ==="

# Ambil input dari pengguna (dengan nilai default)
read -p "Masukkan versi Windows (contoh: 11, 10, xp, 2022) [default: 11]: " VERSION
VERSION=${VERSION:-11}

read -p "Masukkan port untuk Web Viewer [default: 8006]: " WEB_PORT
WEB_PORT=${WEB_PORT:-8006}

read -p "Masukkan port untuk RDP [default: 3390]: " RDP_PORT
RDP_PORT=${RDP_PORT:-3390}

read -p "Masukkan username [default: docker]: " USERNAME
USERNAME=${USERNAME:-docker}

read -sp "Masukkan password [default: admin]: " PASSWORD
echo
PASSWORD=${PASSWORD:-admin}

read -p "Ukuran disk (contoh: 64G, 128G) [default: 64G]: " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-64G}

read -p "Jumlah RAM (contoh: 4G, 8G) [default: 4G]: " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-4G}

read -p "Jumlah CPU core (contoh: 2, 4) [default: 2]: " CPU_CORES
CPU_CORES=${CPU_CORES:-2}

STORAGE_DIR="./windows"
mkdir -p "$STORAGE_DIR"

# Jalankan kontainer Docker
echo -e "\nMenjalankan kontainer Windows VM..."
docker run -it --rm \
  --name windows \
  -p ${WEB_PORT}:8006 \
  -p ${RDP_PORT}:3389/tcp \
  -p ${RDP_PORT}:3389/udp \
  --device=/dev/kvm \
  --device=/dev/net/tun \
  --cap-add NET_ADMIN \
  -e VERSION="${VERSION}" \
  -e USERNAME="${USERNAME}" \
  -e PASSWORD="${PASSWORD}" \
  -e DISK_SIZE="${DISK_SIZE}" \
  -e RAM_SIZE="${RAM_SIZE}" \
  -e CPU_CORES="${CPU_CORES}" \
  -v "${PWD}/windows:/storage" \
  --stop-timeout 120 \
  dockurr/windows

echo -e "\n✅ Selesai!"
echo "Web Viewer: http://localhost:${WEB_PORT}"
echo "RDP: localhost:${RDP_PORT} (user: ${USERNAME}, pass: ${PASSWORD})"
