#
SSH_PUB_KEY = ENV.fetch("SSH_PUB_KEY", File.expand_path("~/.ssh/id_rsa.pub"))
# Save as Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"  # small, current Ubuntu LTS amd64
  config.vm.hostname = "ubuntuS"

  # Forwarded ports: host 2222->guest 22 (ssh), host 8080->guest 8080
  config.vm.network "forwarded_port", guest: 22,   host: 2222, id: "ssh", auto_correct: true
  config.vm.network "forwarded_port", guest: 8081, host: 8081, auto_correct: true
  config.vm.network "forwarded_port", guest: 8080, host: 80, auto_correct: true
  config.vm.network "forwarded_port", guest: 6445, host: 6445, auto_correct: true

  # Resources (low by default)
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.cpus = 6
    vb.memory = 4096
    # Turn on nested VT-x/AMD-V
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    # Optional: expose host CPU profile (helps guests see modern flags)
    vb.customize ["modifyvm", :id, "--cpu-profile", "host"]
  end

  # Provision: run your install script on first boot
  # Put your script next to the Vagrantfile as install.sh
  if File.exist?(SSH_PUB_KEY)
      config.vm.provision "file",
        source: SSH_PUB_KEY,
        destination: "/home/vagrant/host_id.pub"
  end
  config.vm.provision "file", source: "install.sh", destination: "/tmp/install.sh"
  config.vm.provision "shell", inline: <<-SHELL
    set -e
    chmod +x /tmp/install.sh
    if [ -f /home/vagrant/host_id.pub ]; then
      install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
      cat /home/vagrant/host_id.pub >> /home/vagrant/.ssh/authorized_keys
      chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
    fi

    #/tmp/install.sh
  SHELL
end

