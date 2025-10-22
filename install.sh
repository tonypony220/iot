
setssh() {
	# Install basic tools
	apt-get update && apt-get install -y git openssh-client

	# Generate SSH key (skip if already exists)
	if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
		ssh-keygen -t ed25519 -C "tony8pony@gmail.com" -f ~/.ssh/id_ed25519 -N ""
	fi

	# Start ssh-agent
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519

	# Ensure proper permissions
	chmod 700 ~/.ssh
	chmod 600 ~/.ssh/id_ed25519
	chmod 644 ~/.ssh/id_ed25519.pub

	# Print the public key so you can copy it to GitHub
	echo "Add this SSH key to GitHub (https://github.com/settings/keys):"
	cat ~/.ssh/id_ed25519.pub
}

setssh()

install_vagrant()  {

#install vagrant:
#wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
#echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
#sudo apt update && sudo apt install vagrant

	# 1) Put the key in the modern keyrings dir (quiet download)
	sudo install -d -m 0755 /etc/apt/keyrings
	curl -fsSL https://apt.releases.hashicorp.com/gpg \
	  | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
	sudo chmod 0644 /etc/apt/keyrings/hashicorp.gpg

	# 2) Add the repo (Jammy = Ubuntu 22.04)
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/hashicorp.gpg] \
	https://apt.releases.hashicorp.com jammy main" \
	| sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

	# 3) (Optional) Verify the key fingerprint BEFORE installing
	gpg --show-keys --with-fingerprint /etc/apt/keyrings/hashicorp.gpg
	# Expect: 798A EC65 4E5C 1542 8C8E 42EE AA16 FCBC A621 E701

	# 4) Install
	sudo apt update
	sudo apt install vagrant
}

install_vagrant()

install_kctl {
	sudo snap install kubectl --classic
}
install_kctl()

install_vb()  {
	#	install virtualbox
	sudo apt-get install virtualbox
	#	DKMS = Dynamic Kernel Module Support.
	#	It’s a system that automatically rebuilds kernel modules (like VirtualBox’s kernel drivers) whenever you update or change your Linux kernel.
	#	VirtualBox’s kernel drivers (vboxdrv, vboxnetflt, vboxnetadp, etc.) must match your running kernel version.
	#	If you just installed VirtualBox but didn’t have the kernel headers or dkms in place, its modules can’t compile — hence /dev/vboxdrv missing.
	sudo apt install --reinstall linux-headers-$(uname -r) virtualbox-dkms dkms
}

install_vm()

# ssh -fN -R 10022:localhost:2222 root@212.24.101.55
