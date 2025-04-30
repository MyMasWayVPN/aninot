#!/bin/bash

# --- INSTALL MODUL YANG DIPERLUKAN ---

# Periksa dan install wget, gunzip, qemu
echo "Memeriksa apakah modul yang diperlukan sudah terpasang..."

# Cek dan install wget
if ! command -v wget &> /dev/null
then
  echo "wget belum terpasang. Menginstall wget..."
  sudo apt-get update && sudo apt-get install -y wget
fi

# Cek dan install gunzip
if ! command -v gunzip &> /dev/null
then
  echo "gunzip belum terpasang. Menginstall gunzip..."
  sudo apt-get update && sudo apt-get install -y gzip
fi

# Cek dan install qemu
if ! command -v qemu-system-x86_64 &> /dev/null
then
  echo "qemu belum terpasang. Menginstall qemu..."
  sudo apt-get update && sudo apt-get install -y qemu
fi

echo "Semua modul yang diperlukan sudah terpasang!"

# --- MENU PILIHAN WINDOWS ---
echo "Pilih versi Windows yang ingin dijalankan:"
echo "1. Windows 11 Pro"
echo "2. Windows 11 LTSC"
echo "3. Windows 11 Enterprise"
echo "4. Windows 10 Pro"
echo "5. Windows 10 LTSC"
echo "6. Windows 10 Enterprise"
read -p "Masukkan nomor pilihan (default 1): " win_choice

case $win_choice in
  2) URL="https://example.com/win11-ltsc.qcow2.gz" ;;
  3) URL="https://example.com/win11-enterprise.qcow2.gz" ;;
  4) URL="https://example.com/win10-pro.qcow2.gz" ;;
  5) URL="https://example.com/win10-ltsc.qcow2.gz" ;;
  6) URL="https://example.com/win10-enterprise.qcow2.gz" ;;
  *) URL="https://example.com/win11-pro.qcow2.gz" ;;
esac

# --- DOWNLOAD & EXTRACT ---
IMAGE_NAME="windows.qcow2"
COMPRESSED_NAME="${IMAGE_NAME}.gz"

if [ ! -f "$IMAGE_NAME" ]; then
  echo "Mengunduh image Windows terkompresi..."
  wget -O "$COMPRESSED_NAME" "$URL"
  echo "Ekstrak image..."
  gunzip "$COMPRESSED_NAME"
fi

# --- DISK SIZE OTOMATIS ---
DISK_SIZE=$(df --output=size / | tail -n 1)
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024))
CALC_DISK=$((DISK_SIZE_GB * 80 / 100))

echo "Resize image ke ${CALC_DISK}G..."
qemu-img resize "$IMAGE_NAME" "${CALC_DISK}G"

# --- VGA OPSIONAL ---
read -p "Aktifkan VGA virtio-gpu? (y/n): " vga_input
if [[ "$vga_input" == "y" || "$vga_input" == "Y" ]]; then
  VGA="-vga none -device virtio-gpu-pci"
else
  VGA=""
fi

# --- JALANKAN QEMU ---
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp cores=2 \
  -cpu host \
  -drive file="$IMAGE_NAME",format=qcow2 \
  -net nic -net user,hostfwd=tcp::3389-:3389 \
  $VGA
