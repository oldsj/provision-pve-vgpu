#!/usr/bin/env bash
# shellcheck disable=SC2086

# validate input
if [[ $# -eq 0 ]] ; then
    echo 'usage: ./vgpu.sh NVIDIA_VERSION NVIDIA_ZIP_FILE'
    exit 1
fi

NVIDIA_VERSION=$1
NVIDIA_ZIP_FILE=$2
NVIDIA_RUN_FILE=NVIDIA-Linux-x86_64-${NVIDIA_VERSION}-vgpu-kvm.run 
NVIDIA_RUN_FILE_CUSTOM=NVIDIA-Linux-x86_64-${NVIDIA_VERSION}-vgpu-kvm-custom.run 

echo "[VGPU] verifying IOMMU"
if ! dmesg | grep -q -e DMAR -e IOMMU; then
    echo "[VGPU] error: Ensure IOMMU is enabled https://gitlab.com/polloloco/vgpu-proxmox#enabling-iommu"
    exit 1
fi

echo "[VGPU] installing dependencies"
apt-get update && apt-get install -y \
    git build-essential dkms "pve-headers-$(uname -r)" mdevctl

echo "[VGPU] installing rust"
command -v cargo || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
# shellcheck disable=SC1091
source "$HOME/.cargo/env"

echo "[VGPU] cloning repos"
cd "$HOME" || exit 1
[[ -d vgpu-proxmox/ ]] || \
    git clone https://gitlab.com/polloloco/vgpu-proxmox.git
cd /opt || exit 1
[[ -d vgpu_unlock-rs/ ]] || \
    git clone https://github.com/mbilker/vgpu_unlock-rs.git

if [[ ! -f vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so ]]; then
    echo "[VGPU] building vgpu_unlock-rs"
    cd vgpu_unlock-rs/ || exit 1
    cargo build --release
fi

echo "[VGPU] preparing vgpu_unlock"
mkdir -p /etc/vgpu_unlock
touch /etc/vgpu_unlock/profile_override.toml
mkdir -p /etc/systemd/system/{nvidia-vgpud.service.d,nvidia-vgpu-mgr.service.d}
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpud.service.d/vgpu_unlock.conf
echo -e "[Service]\nEnvironment=LD_PRELOAD=/opt/vgpu_unlock-rs/target/release/libvgpu_unlock_rs.so" > /etc/systemd/system/nvidia-vgpu-mgr.service.d/vgpu_unlock.conf

# update modules and reboot if necessary 
REBOOT=0
if ! grep -q 'vfio_virqfd' /etc/modules; then
    echo "[VGPU] adding vfio modules"
    echo -e "vfio\nvfio_iommu_type1\nvfio_pci\nvfio_virqfd" >> /etc/modules
    REBOOT=1
fi
if [[ ! -f /etc/modprobe.d/nvidia-installer-disable-nouveau.conf ]]; then
    echo "[VGPU] blocking the opensource nvidia driver from running"
    echo "blacklist nouveau" > /etc/modprobe.d/nvidia-installer-disable-nouveau.conf 
    REBOOT=1
fi
if [[ ${REBOOT} == 1 ]]; then
    echo "[VGPU] rebooting, re-run the provisioning script when pve host is back online"
    reboot
fi

# install the nvidia driver
cd "$HOME" || exit 1
if [[ ! -d nvidia-${NVIDIA_VERSION}/ ]]; then
    unzip "${NVIDIA_ZIP_FILE}" -d "nvidia-${NVIDIA_VERSION}/"
fi

cd "nvidia-${NVIDIA_VERSION}/Host_Drivers" || exit 1
chmod +x "${NVIDIA_RUN_FILE}"
echo "[VGPU] validating the nvidia driver"
./${NVIDIA_RUN_FILE} --check
echo "[VGPU] patching the nvidia driver"
if [[ ! -f ${NVIDIA_RUN_FILE_CUSTOM} ]]; then
    ./${NVIDIA_RUN_FILE} --apply-patch ~/vgpu-proxmox/"${NVIDIA_VERSION}.patch"
    echo "[VGPU] installing the patched driver"
    ./${NVIDIA_RUN_FILE_CUSTOM} --dkms --silent
fi

echo "[VGPU] verifying vGPU status"
if nvidia-smi vgpu | grep "${NVIDIA_VERSION}"; then
    echo "[VGPU] installation complete!"
else
    echo "[VGPU] something went wrong, vGPU not detected"
    exit 1
fi
