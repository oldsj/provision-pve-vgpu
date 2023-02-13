#!/usr/bin/env bash

# validate input
if [[ $# -eq 0 ]] ; then
    echo 'usage: ./provision.sh NVIDIA_VERSION NVIDIA_ZIP_FILE PVE_HOST_SSH'
    exit 1
fi

NVIDIA_VERSION=$1
NVIDIA_ZIP_PATH=$2
PVE_HOST_SSH=$3
NVIDIA_ZIP_FILE=$(basename "${NVIDIA_ZIP_PATH}")

echo "[PROVISION] running pve provisioning script"
ssh "${PVE_HOST_SSH}" 'bash -s' < ./pve.sh

echo "[PROVISION] copying nvidia driver ${NVIDIA_ZIP_PATH} to the pve host"
ssh -q "${PVE_HOST_SSH}" [[ -f "${NVIDIA_ZIP_FILE}" ]] || \
    scp "${NVIDIA_ZIP_PATH}" "${PVE_HOST_SSH}":~/

echo "[PROVISION] running vGPU provisioning script"
# shellcheck disable=SC2029
ssh "${PVE_HOST_SSH}" 'bash -s' < ./vgpu.sh "${NVIDIA_VERSION}" "${NVIDIA_ZIP_FILE}"

echo "[PROVISION] copying vGPU profile configuration"
scp ../config/profile_override.toml "${PVE_HOST_SSH}":/etc/vgpu_unlock/profile_override.toml
