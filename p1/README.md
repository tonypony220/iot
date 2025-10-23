export KUBECONFIG=./kubeconfig
kubectl get nodes -o wide

vagrant box list
vagrant box remove bento/ubuntu-22.04

# List network adapters:
VBoxManage list hostonlyifs

# VM registered:
VBoxManage list vms
VBoxManage showvminfo <vm_name>

# Check the NAT and Host-only networks exist:
VBoxManage list natnets


VAGRANT_LOG=info vagrant up
VAGRANT_LOG=debug vagrant up


# inside machine: 

udo systemctl status k3s
sudo journalctl -xeu k3s --no-pager
sudo systemctl status network
ip a
cat /etc/netplan/*.yaml


curl -k https://192.168.56.110:6443/readyz

