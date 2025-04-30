#!/bin/bash

# Pastikan Docker tersedia
if ! command -v docker &> /dev/null; then
  echo "Docker belum terinstal. Silakan instal Docker terlebih dahulu."
  exit 1
fi

# --- MENU WINDOWS VERSION ---
echo "Pilih versi Windows:"
echo "01 | 1) Windows 11 Pro (4.8GB)"
echo "02 | 2) Windows 11 LTSC (4.7GB)"
echo "03 | 3) Windows 11 Enterprise (4.8GB)"
echo "04 | 4) Windows 10 Pro (3.5GB)"
echo "05 | 5) Windows 10 LTSC (4.1GB)"
echo "06 | 6) Windows 10 Enterprise (3.4GB)"
read -p "Masukkan nomor (default 1): " win_choice

case "$win_choice" in
  2|02) VERSION="11l" ;;
  3|03) VERSION="11e" ;;
  4|04) VERSION="10" ;;
  5|05) VERSION="10l" ;;
  6|06) VERSION="10e" ;;
  1|01|"") VERSION="11" ;;  # Default ke Windows 11 Pro
  *) VERSION="11" ;;         # Jika input tidak valid
esac

# --- USERNAME & PASSWORD ---
read -p "Masukkan username untuk Windows: " USERNAME
read -sp "Masukkan password untuk Windows: " PASSWORD
echo

# --- DISK SIZE OTOMATIS ---
DISK_SIZE=$(df --output=size / | tail -n 1)
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024))

if [[ "$DISK_SIZE_GB" -lt 10 ]]; then
  echo "Disk terlalu kecil. Dibutuhkan minimal 10GB."
  exit 1
fi

CALC_DISK=$((DISK_SIZE_GB * 80 / 100))G

# --- PORT SETUP ---
read -p "Port host untuk noVNC (default 8006): " HOST_PORT
HOST_PORT=${HOST_PORT:-8006}

read -p "Port host untuk RDP (default 3390): " RDP_PORT
RDP_PORT=${RDP_PORT:-3390}

# --- VGA OPSIONAL ---
read -p "Aktifkan VGA (virtio-gpu)? (y/n): " vga_input
if [[ "$vga_input" =~ ^[Yy]$ ]]; then
  VGA="virtio-gpu"
else
  VGA=""
fi

# --- CEK CONTAINER SUDAH ADA ---
if docker ps -a --format '{{.Names}}' | grep -wq windows; then
  echo "Container bernama 'windows' sudah ada. Menghapus dulu..."
  docker rm -f windows
fi

# --- JALANKAN DOCKER ---
docker run -d --name windows \
  -e USERNAME="$USERNAME" \
  -e PASSWORD="$PASSWORD" \
  -e VERSION="$VERSION" \
  -e DISK_SIZE="$CALC_DISK" \
  ${VGA:+-e VGA="$VGA"} \
  -p "$HOST_PORT:8006" \
  -p "$RDP_PORT:3389" \
  --privileged \
  --restart unless-stopped \
  dockurr/windows
