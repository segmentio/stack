
SRC = $(wildcard *.tf ./*/*.tf)
platform := $(shell uname)
pydeps := pyyaml boto3
modules = $(shell ls -1 ./*.tf ./*/*.tf | xargs -I % dirname %)

# The install rule sets up the development environment on the machine it's ran
# on.
install: install-third-party-tools install-python-dependencies install-tools

ifeq (${platform},Darwin)
install-third-party-tools:
	brew install packer terraform python3
else
install-third-party-tools:
	@echo "${platform} is a platform we have no presets for, you'll have to install the third party dependencies manually (packer, terraform, python3)"
endif

ifeq (${platform},Darwin)
install-python-dependencies:
	sudo -H pip install --upgrade ${pydeps}
else
install-python-dependencies:
	pip install --upgrade pyyaml boto3
endif

install-tools:
	go install ./cmd

test:
	@bash scripts/test.sh

docs.md: $(SRC)
	@bash scripts/docs.sh

.PHONY: install-third-party-tools install-python-dependencies build-ami plan-ami validate-ami amis
