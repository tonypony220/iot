#!/bin/bash

set -e
set -u
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting host VM setup on $(hostname)..."

resize_disk() {

  set -e
  echo "[1/5] Layout:"; lsblk

  # Try to grow the last partition if it's a simple /dev/sda3 case; ignore NOCHANGE
  if [ -b /dev/sda3 ]; then
    echo "[2/5] growpart (may say NOCHANGE)..."
    sudo apt-get update -y >/dev/null
    sudo apt-get install -y cloud-guest-utils >/dev/null
    sudo growpart /dev/sda 3 || true
  else
    echo "[2/5] Skipping growpart (no /dev/sda3)."
  fi

  # Identify root LV and filesystem
  ROOT_SRC=$(findmnt -no SOURCE /)          # e.g. /dev/mapper/ubuntu--vg-ubuntu--lv
  FSTYPE=$(findmnt -no FSTYPE /)            # ext4 or xfs expected
  VG=$(lvs --noheadings -o vg_name "$ROOT_SRC" 2>/dev/null | awk '{$1=$1};1')
  LV=$(lvs --noheadings -o lv_name "$ROOT_SRC" 2>/dev/null | awk '{$1=$1};1')

  echo "[3/5] pvresize..."
  # Common Ubuntu Vagrant layout uses /dev/sda3 as the PV
  if [ -b /dev/sda3 ]; then
    sudo pvresize /dev/sda3 || true
  fi

  echo "[4/5] lvextend to use all free space..."
  sudo lvextend -l +100%FREE "/dev/${VG}/${LV}"

  echo "[5/5] Grow filesystem (${FSTYPE})..."
  if [ "$FSTYPE" = "ext4" ]; then
    sudo resize2fs "/dev/${VG}/${LV}"
  elif [ "$FSTYPE" = "xfs" ]; then
    sudo xfs_growfs /
  else
    echo "Unknown fs $FSTYPE — not resizing"; exit 1
  fi

  echo "✅ Done:"
  df -h /
}


install_base_deps() {
    log "Installing base dependencies (make, curl, net-tools)..."

    if command -v make >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
        log "Base dependencies already installed, skipping"
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y make curl net-tools

    log "Base dependencies installed successfully"
}

setup_ssh() {
    log "Setting up SSH key..."

    # Install openssh-client if not present
    if ! command -v git >/dev/null 2>&1; then
        log "Installing openssh-client..."
        sudo apt-get update
        sudo apt-get install -y openssh-client
    else
        log "openssh-client already installed"
    fi
}

install_vagrant() {
    log "Installing Vagrant..."

    if command -v vagrant >/dev/null 2>&1; then
        log "Vagrant already installed ($(vagrant --version)), skipping"
        return 0
    fi

    # Install keyring directory
    sudo install -d -m 0755 /etc/apt/keyrings

    # Add HashiCorp GPG key
    log "Adding HashiCorp GPG key..."
    curl -fsSL https://apt.releases.hashicorp.com/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
    sudo chmod 0644 /etc/apt/keyrings/hashicorp.gpg

    # Add HashiCorp repository
    log "Adding HashiCorp repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] \
https://apt.releases.hashicorp.com jammy main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

    # Install Vagrant
    log "Installing Vagrant package..."
    sudo apt-get update
    sudo apt-get install -y vagrant

    log "Vagrant installed successfully: $(vagrant --version)"
}

install_kubectl() {
    log "Installing kubectl..."

    if command -v kubectl >/dev/null 2>&1; then
        log "kubectl already installed ($(kubectl version --client --short 2>/dev/null || echo 'version unknown')), skipping"
        return 0
    fi

    log "Installing kubectl via snap..."
    sudo snap install kubectl --classic

    log "kubectl installed successfully"
}

install_helm() {
	sudo snap install helm --classic
}

install_k3d()  {
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_docker() {
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
  docker --version
  #docker compose version
}

install_virtualbox() {
    log "Installing VirtualBox..."

    if command -v VBoxManage >/dev/null 2>&1; then
        log "VirtualBox already installed ($(VBoxManage --version)), skipping"
        return 0
    fi

    log "Installing VirtualBox and kernel modules..."
    sudo apt-get update
    sudo apt-get install -y virtualbox

    # Install DKMS and kernel headers for VirtualBox kernel modules
    # DKMS = Dynamic Kernel Module Support
    # Automatically rebuilds kernel modules when kernel is updated
    log "Installing DKMS and kernel headers..."
    sudo apt-get install -y linux-headers-$(uname -r) linux-headers-generic build-essential dkms virtualbox-dkms
    sudo dpkg-reconfigure virtualbox-dkms
    sudo dpkg-reconfigure virtualbox

    log "VirtualBox installed successfully: $(VBoxManage --version)"
}

main() {
    log "=== Starting installation process ==="

    install_base_deps
    resize_disk
    setup_ssh
    install_vagrant
    install_virtualbox
    install_kubectl
    install_helm
    install_k3d
    install_docker

    log "=== Installation complete ==="
    log "System is ready for running nested VMs with Vagrant + VirtualBox"
    log ""
    log "Next steps:"
    log "  1. Add your SSH key to GitHub if needed"
    log "  2. Clone your project repositories"
    log "  3. Navigate to project directory and run 'make up'"
}

# Run main function
main
