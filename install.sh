#!/usr/bin/env bash
set -euo pipefail

setssh() {
  # Install basic tools
  sudo apt-get update -y
  sudo apt-get install -y git openssh-client curl ca-certificates gnupg

  # Ensure ~/.ssh exists & perms
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Generate SSH key (skip if already exists)
  if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "tony8pony@gmail.com" -f "$HOME/.ssh/id_ed25519" -N ""
  fi

  # Start ssh-agent & add key
  eval "$(ssh-agent -s)"
  ssh-add "$HOME/.ssh/id_ed25519"

  # Correct perms
  chmod 600 "$HOME/.ssh/id_ed25519"
  chmod 644 "$HOME/.ssh/id_ed25519.pub"

  # Show public key
  echo "Add this SSH key to GitHub (https://github.com/settings/keys):"
  cat "$HOME/.ssh/id_ed25519.pub"
}

install_vagrant() {
  # Keyring
  sudo install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
  sudo chmod 0644 /etc/apt/keyrings/hashicorp.gpg

  # Repo (auto-detect codename, e.g. jammy for 22.04)
  CODENAME="$(. /etc/os-release && echo "$UBUNTU_CODENAME")"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

  # (Optional) fingerprint check
  gpg --show-keys --with-fingerprint /etc/apt/keyrings/hashicorp.gpg

  sudo apt-get update -y
  sudo apt-get install -y vagrant
}

install_kctl() {
  # Install kubectl via snap
  sudo snap install kubectl --classic
}

install_vb() {
  # VirtualBox + DKMS + headers (needed for kernel modules)
  sudo apt-get update -y
  sudo apt-get install -y virtualbox virtualbox-dkms dkms "linux-headers-$(uname -r)"
}

# ---- Run steps ----
setssh
install_vagrant
install_kctl
install_vb

