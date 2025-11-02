# User Configuration
LOGIN ?= apending
BOX_IMAGE ?= bento/ubuntu-22.04

# Network Configuration
SERVER_IP ?= 192.168.56.110
WORKER_IP ?= 192.168.56.111

# VM Resources
VM_MEMORY ?= 1024
VM_CPUS ?= 1

# Provider
PROVIDER ?= virtualbox

# Token Configuration
SHARED_TOKEN_PATH ?= /vagrant/token

# Export all variables for Vagrant
export LOGIN
export BOX_IMAGE
export SERVER_IP
export WORKER_IP
export VM_MEMORY
export VM_CPUS
export PROVIDER
export SHARED_TOKEN_PATH

all: up

check-env:
	@if [ -z "$(LOGIN)" ]; then \
		echo "ERROR: LOGIN is not set"; \
		exit 1; \
	fi

up: check-env
	@echo "Starting Part 1 VMs..."
	@echo "Server: $(LOGIN)S ($(SERVER_IP))"
	@echo "Worker: $(LOGIN)SW ($(WORKER_IP))"
	vagrant up
	@echo "VMs started successfully!"

down:
	vagrant halt

status:
	@vagrant ssh $(LOGIN)S -c "sudo kubectl get nodes -o wide" 2>/dev/null || echo "Failed to get cluster status."

ssh-server:
	vagrant ssh $(LOGIN)S

ssh-worker:
	vagrant ssh $(LOGIN)SW

reload:
	vagrant reload --provision

clean:
	vagrant destroy -f
	@rm -f token
	@rm -rf .vagrant

.PHONY: help check-env up down status ssh-server ssh-worker reload clean
