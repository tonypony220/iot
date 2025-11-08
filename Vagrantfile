# -*- mode: ruby -*-
# vi: set ft=ruby :

# Read configuration from environment variables
BOX_IMAGE = ENV['BOX_IMAGE']
VM_HOSTNAME = ENV['VM_HOSTNAME']
VM_MEMORY = ENV['VM_MEMORY'] || '4096'
VM_CPUS = ENV['VM_CPUS'] || '6'
PROVIDER = ENV['PROVIDER'] || 'virtualbox'

Vagrant.configure("2") do |config|
  # Base configuration
  config.vm.box = BOX_IMAGE
  config.vm.hostname = VM_HOSTNAME

  # Forwarded ports
  config.vm.network "forwarded_port", guest: 22,   host: 2222, id: "ssh", auto_correct: true
  config.vm.network "forwarded_port", guest: 8081, host: 8081, auto_correct: true
  config.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true
  config.vm.network "forwarded_port", guest: 6445, host: 6445, auto_correct: true

  # VirtualBox provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = VM_CPUS
    vb.memory = VM_MEMORY
    # Enable nested virtualization for running VMs inside this VM
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    # Expose host CPU profile to guest
    vb.customize ["modifyvm", :id, "--cpu-profile", "host"]
  end

  config.vm.disk :disk, size: "60GB", name: "docker-data"

  # Parallels provider configuration
  config.vm.provider "parallels" do |prl|
    prl.cpus = VM_CPUS
    prl.memory = VM_MEMORY
  end

  config.vm.provision "shell" do |s|
      s.path = "install.sh"
      s.env = {}
  end
end
