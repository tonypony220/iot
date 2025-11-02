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

# Function: Install base dependencies
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

# Function: Setup SSH key
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

# Function: Install Vagrant
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

# Function: Install kubectl
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

# Function: Install VirtualBox
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
    sudo apt-get install -y linux-headers-$(uname -r) virtualbox-dkms dkms

    log "VirtualBox installed successfully: $(VBoxManage --version)"
}

# Main execution
main() {
    log "=== Starting installation process ==="

    install_base_deps
    setup_ssh
    install_vagrant
    install_kubectl
    install_virtualbox

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
