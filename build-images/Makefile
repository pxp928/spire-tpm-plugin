include .env

REGISTRY ?= ghcr.io/pxp928
BASE_IMAGE_STAGE ?= distroless-base

PLATFORMS ?= linux/amd64,linux/arm64
VERSION ?= develop
TAGS ?= $(VERSION)
PROGRESS ?= plain

DOCKER_TARGETS ?= spire-agent spire-server spire-tools socat-spire-agent socat-spire-server

target = $@
DOCKER_TAGS = $(foreach tag, $(TAGS),--tag $(REGISTRY)/spire/$(target):$(tag))

.PHONY: docker $(DOCKER_TARGETS)

docker: $(DOCKER_TARGETS)
$(DOCKER_TARGETS):
	docker buildx build \
		--target $(target) \
		--platform $(PLATFORMS) \
		--build-arg REGISTRY=$(REGISTRY) \
		--build-arg SPIRE_VERSION=$(SPIRE_VERSION) \
		--build-arg SPIRE_TPM_PLUGIN_VERSION=$(SPIRE_TPM_PLUGIN_VERSION) \
		--build-arg BASE_IMAGE_STAGE=$(BASE_IMAGE_STAGE) \
		$(DOCKER_TAGS) \
		--push \
		--progress $(PROGRESS) \
		.
