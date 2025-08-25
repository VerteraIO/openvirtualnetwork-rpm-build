# OVN RPM Builder Makefile

# Default OVN version (can be overridden)
OVN_VERSION ?= 24.09.0
DISTRO ?= rockylinux
VERSION ?= 9

# Docker image configuration
IMAGE_NAME = ovn-rpm-builder
CONTAINER_NAME = ovn-rpm-build-$(DISTRO)-$(VERSION)

# Output directory
OUTPUT_DIR = output

.PHONY: help build build-el9 build-el10 clean clean-all

help:
	@echo "OVN RPM Builder"
	@echo ""
	@echo "Usage:"
	@echo "  make build                    - Build RPMs for Rocky Linux 9 (default)"
	@echo "  make build-el9                - Build RPMs for Enterprise Linux 9"
	@echo "  make build-el10               - Build RPMs for Enterprise Linux 10"
	@echo "  make clean                    - Clean build containers and images"
	@echo "  make clean-all                - Clean everything including output"
	@echo ""
	@echo "Variables:"
	@echo "  OVN_VERSION=24.09.0          - OVN version to build"
	@echo "  DISTRO=rockylinux            - Base distribution (rockylinux, almalinux)"
	@echo "  VERSION=9                    - Distribution version (9, 10)"
	@echo ""
	@echo "Examples:"
	@echo "  make build OVN_VERSION=24.03.0"
	@echo "  make build-el10 DISTRO=almalinux"

build: build-el9

build-el9:
	@echo "Building OVN $(OVN_VERSION) RPMs for Enterprise Linux 9..."
	@mkdir -p $(OUTPUT_DIR)
	docker build \
		--build-arg DISTRO=rockylinux \
		--build-arg VERSION=9 \
		--build-arg OVN_VERSION=$(OVN_VERSION) \
		-t $(IMAGE_NAME):el9 \
		-f Dockerfile .
	docker run --rm \
		--name $(CONTAINER_NAME)-el9 \
		-v $(PWD)/$(OUTPUT_DIR):/output \
		$(IMAGE_NAME):el9

build-el10:
	@echo "Building OVN $(OVN_VERSION) RPMs for Enterprise Linux 10..."
	@mkdir -p $(OUTPUT_DIR)
	docker build \
		--build-arg DISTRO=rockylinux \
		--build-arg VERSION=10 \
		--build-arg OVN_VERSION=$(OVN_VERSION) \
		-t $(IMAGE_NAME):el10 \
		-f Dockerfile .
	docker run --rm \
		--name $(CONTAINER_NAME)-el10 \
		-v $(PWD)/$(OUTPUT_DIR):/output \
		$(IMAGE_NAME):el10

clean:
	@echo "Cleaning build containers and images..."
	-docker rm -f $(shell docker ps -aq --filter "name=$(CONTAINER_NAME)")
	-docker rmi -f $(shell docker images -q $(IMAGE_NAME))

clean-all: clean
	@echo "Cleaning output directory..."
	rm -rf $(OUTPUT_DIR)

# Development targets
shell-el9:
	docker run --rm -it \
		--name $(CONTAINER_NAME)-el9-shell \
		-v $(PWD)/$(OUTPUT_DIR):/output \
		$(IMAGE_NAME):el9 /bin/bash

shell-el10:
	docker run --rm -it \
		--name $(CONTAINER_NAME)-el10-shell \
		-v $(PWD)/$(OUTPUT_DIR):/output \
		$(IMAGE_NAME):el10 /bin/bash
