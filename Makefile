# User Configuration
BOX_IMAGE ?= bento/ubuntu-22.04
VM_HOSTNAME ?= evaluationVM

# VM Resources
VM_MEMORY ?= 4096
VM_CPUS ?= 6

# Provider
PROVIDER ?= virtualbox

# Export all variables for Vagrant
export BOX_IMAGE
export VM_HOSTNAME
export VM_MEMORY
export VM_CPUS
export PROVIDER

all: up

check-env:
	@if [ -z "$(VM_HOSTNAME)" ]; then \
		echo "ERROR: VM_HOSTNAME is not set"; \
		exit 1; \
	fi

up: check-env
	@echo "Starting host VM..."
	@echo "Hostname: $(VM_HOSTNAME)"
	@echo "Resources: $(VM_CPUS) CPUs, $(VM_MEMORY) MB RAM"
	vagrant up
	@echo "VM started successfully!"
	@echo "Use 'make ssh' to connect to the VM"

down:
	vagrant halt

status:
	vagrant status

ssh:
	vagrant ssh

reload:
	vagrant reload --provision

clean:
	vagrant destroy -f
	@rm -rf .vagrant

.PHONY: all help check-env up down status ssh reload clean
