# User Configuration
LOGIN ?= apending
BOX_IMAGE ?= generic/ubuntu2204

# Network Configuration
SERVER_IP ?= 192.168.56.110

# VM Resources
VM_MEMORY ?= 1024
VM_CPUS ?= 1

# Provider
PROVIDER ?= virtualbox

# Export all variables for Vagrant
export LOGIN
export BOX_IMAGE
export SERVER_IP
export VM_MEMORY
export VM_CPUS
export PROVIDER

all: check-env up

check-env:
	@if [ -z "$(LOGIN)" ]; then \
		echo "ERROR: LOGIN is not set"; \
		exit 1; \
	fi

up: check-env
	@echo "Starting Part 2 VM..."
	@echo "Server: $(LOGIN)S ($(SERVER_IP))"
	vagrant up

down:
	vagrant halt

status:
	@vagrant ssh $(LOGIN)S -c "sudo kubectl get nodes -o wide && echo && sudo kubectl get deployments,pods,svc,ingress" 2>/dev/null || echo "Failed to get status"

test:
	@echo "Testing Ingress Routing:"
	@echo ""
	@echo "Test 1: app1.com → app1"
	@curl -s -H "Host: app1.com" http://$(SERVER_IP) || echo "Failed"
	@echo ""
	@echo "Test 2: app2.com → app2"
	@curl -s -H "Host: app2.com" http://$(SERVER_IP) || echo "Failed"
	@echo ""
	@echo "Test 3: default → app3"
	@curl -s http://$(SERVER_IP) || echo "Failed"
	@echo ""
	@echo "Tests complete"

ssh:
	vagrant ssh $(LOGIN)S

reload:
	vagrant reload --provision

clean:
	vagrant destroy -f
	@rm -rf .vagrant

.PHONY: check-env up down status test ssh reload clean
