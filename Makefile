PVE_HOST_SSH = root@pve1
NVIDIA_VERSION = 510.108.03
NVIDIA_ZIP_PATH = ~/Downloads/NVIDIA-GRID-Linux-KVM-510.108.03-514.08.zip

.PHONY: provision
provision:
	cd scripts/; \
	./provision.sh ${NVIDIA_VERSION} ${NVIDIA_ZIP_PATH} ${PVE_HOST_SSH}

.PHONY: uninstall
uninstall:
	cd scripts/; \
	ssh "${PVE_HOST_SSH}" 'bash -s' < ./vgpu_uninstall.sh "${NVIDIA_VERSION}" 

.PHONY: license
license:
	cd scripts/; \
	ssh "${PVE_HOST_SSH}" 'bash -s' < ./license.sh

