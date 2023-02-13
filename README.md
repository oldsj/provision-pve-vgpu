# provision-pve-vgpu

A set of scripts to provision a Proxmox VE host with Nvidia vGPU support.

Automates the guide at https://gitlab.com/polloloco/vgpu-proxmox

## Getting Started

### Download a driver

Note: use driver version 14.4 for compatibility with alternate licensing options.
See https://gitlab.com/polloloco/vgpu-proxmox#nvidia-driver for obtaining a vGPU driver and save the zip to ~/Downloads.

Take a look at the [Makefile](./Makefile) and make any updates to the variables at the top if needed.

### Configure vGPU profiles

Configure your vGPU profiles in [config/profile_override.toml](config/profile_override.toml)

See https://gitlab.com/polloloco/vgpu-proxmox#vgpu-overrides


### Provision the Proxmox host

`make provision`
