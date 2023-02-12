#!/usr/bin/env bash

# validate input
if [[ $# -eq 0 ]] ; then
    echo 'usage: ./vgpu_uninstall.sh NVIDIA_VERSION'
    exit 1
fi

NVIDIA_VERSION=$1
NVIDIA_RUN_FILE_CUSTOM="NVIDIA-Linux-x86_64-${NVIDIA_VERSION}-vgpu-kvm-custom.run"


cd "$HOME/nvidia-${NVIDIA_VERSION}/Host_Drivers" || exit 1
# shellcheck disable=SC2086
./${NVIDIA_RUN_FILE_CUSTOM} --uninstall --silent || exit 1

rm -rf "$HOME/nvidia-${NVIDIA_VERSION}/"
rm -rf "$HOME/vgpu-proxmox/"
rm -rf /opt/vgpu_unlock-rs/
rm -rf /etc/vgpu_unlock
rm -f /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf
rm -f /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf
rm -f /etc/modprobe.d/nvidia-installer-disable-nouveau.conf

echo "[CLEAN] cleanup complete, rebooting"
reboot
