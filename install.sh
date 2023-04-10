#!/bin/bash

# Update the system
sudo pacman -Syu

# Detect GPU
gpu_vendor=$(lspci -nnk | grep -i vga -A3 | grep 'vendor' | sed 's/.*: //')
if [[ $gpu_vendor == *"NVIDIA"* ]]; then
    gpu_driver="nvidia"
    sudo pacman -S --noconfirm nvidia-dkms nvidia-settings nvidia-utils opencl-nvidia lib32-opencl-nvidia
elif [[ $gpu_vendor == *"AMD"* ]]; then
    gpu_driver="amdgpu"
    sudo pacman -S --noconfirm xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon mesa lib32-mesa mesa-vdpau lib32-mesa-vdpau libva-mesa-driver lib32-libva-mesa-driver vulkan-icd-loader lib32-vulkan-icd-loader libva lib32-libva libdrm lib32-libdrm
elif [[ $gpu_vendor == *"Intel"* ]]; then
    gpu_driver="intel"
    sudo pacman -S --noconfirm xf86-video-intel vulkan-intel libva-intel-driver lib32-vulkan-intel libvulkan-intel lib32-libva-intel-driver
fi

# Install necessary packages for gaming
sudo pacman -S --noconfirm gamemode steam lutris

# Enable feral gamemode
sudo mkdir /etc/systemd/user
echo "[D-BUS Service]
Name=uk.co.feralinteractive.GameMode
Exec=/usr/bin/gamemoded" | sudo tee /etc/systemd/user/feral-gamemode.service
systemctl --user enable feral-gamemode.service

# Configure grub to enable intel_iommu=on
sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/quiet/quiet intel_iommu=on/g' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Disable pulseaudio timer scheduling
sudo sed -i 's/; tsched=0/tsched=0/' /etc/pulse/default.pa

# Install power management packages
sudo pacman -S --noconfirm tlp powertop

# Enable tlp service
sudo systemctl enable tlp.service
sudo systemctl enable tlp-sleep.service

# Install and configure thermald
sudo pacman -S --noconfirm thermald
echo "cpu 0-$(($(nproc)-1))" | sudo tee /etc/thermald/thermal-conf.xml

# Set swappiness to 10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.d/99-swappiness.conf

# Set dirty_bytes to 104857600 (100MB)
echo "vm.dirty_bytes=104857600" | sudo tee -a /etc/sysctl.d/99-dirty_bytes.conf

# Enable zswap
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=25 /' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Install and configure zram
sudo pacman -S --noconfirm zramswap
sudo systemctl enable zramswap.service

# Install and configure earlyoom
sudo pacman -S --noconfirm earlyoom
sudo systemctl enable earlyoom.service

# Install and configure timeshift
sudo pacman -S --noconfirm timeshift
sudo timeshift --create --comments "Initial backup"

# Clean up
sudo pacman -Scc --noconfirm

echo "System configuration completed successfully!"
