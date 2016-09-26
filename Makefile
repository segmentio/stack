
SRC = $(wildcard *.tf ./*/*.tf)
platform := $(shell uname)
pydeps := pyyaml boto3
modules = $(shell ls -1 ./*.tf ./*/*.tf | xargs -I % dirname %)

tools := \
	./tools/pack-ami \
	./tools/roll-ami \
	./tools/tfvar-ami

tools := $(patsubst ./tools/%,/usr/local/bin/%,${tools})

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
	sudo -H pip3 install --upgrade ${pydeps}
else
install-python-dependencies:
	pip3 install --upgrade pyyaml boto3
endif

install-tools: $(tools)

/usr/local/bin/%: ./tools/%
	install -S -m 0755 $< /usr/local/bin

amis:
	pack-ami build -p ./packer -t base -r

plan-ami:
	pack-ami plan -p ./packer -t ${template}

validate-ami:
	pack-ami validate -p ./packer -t ${template}

build-ami:
	pack-ami build -p ./packer -t ${template}

test:
	@bash scripts/test.sh

docs.md: $(SRC)
	@bash scripts/docs.sh

.PHONY: install-third-party-tools install-python-dependencies build-ami plan-ami validate-ami amis
