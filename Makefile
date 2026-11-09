IMAGE_NAME := $(shell yq .name deploy/porkbun-webhook/Chart.yaml)
IMAGE_TAG := v$(shell yq .appVersion deploy/porkbun-webhook/Chart.yaml)
NEW_VERSION ?= ""
CHART_VERSION = $(NEW_VERSION:v%=%)

OUT := $(shell pwd)/_out

HELM_FILES := $(shell find deploy/porkbun-webhook)
HELM_PLUGINS := $(shell helm env HELM_PLUGINS)
HELM_UNITTEST_PLUGIN := $(HELM_PLUGINS)/helm-unittest.git

test: 
	go test -v .

.PHONY: build
build:
	docker build -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

.PHONY: vars
vars:
	@echo "OS            = ${OS}"
	@echo "ARCH          = ${ARCH}"
	@echo "IMAGE_NAME    = $(IMAGE_NAME)"
	@echo "IMAGE_TAG     = $(IMAGE_TAG)"
	@echo "HELM PLUGINS  = $(HELM_PLUGINS)"
	@echo "NEW_VERSION   = $(NEW_VERSION)"
	@echo "CHART_VERSION = $(CHART_VERSION)"

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml: $(OUT)/rendered-manifest.yaml

$(OUT)/rendered-manifest.yaml: $(HELM_FILES) | $(OUT)
	helm template \
	    --name porkbun-webhook \
            --set image.repository=$(IMAGE_NAME) \
            --set image.tag=$(IMAGE_TAG) \
            deploy/porkbun-webhook > $@

.PHONY: helm-plugins
helm-plugins: $(HELM_UNITTEST_PLUGIN)

$(HELM_UNITTEST_PLUGIN):
	helm plugin install https://github.com/helm-unittest/helm-unittest.git 

helm-test: $(HELM_UNITTEST_PLUGIN)
	helm unittest deploy/porkbun-webhook/

test-tag:
	test -n "$(NEW_VERSION)" && test -z $(shell git tag --list $(NEW_VERSION))

bump: test-tag helm-test
	yq -i '.appVersion="$(CHART_VERSION)", .version="$(CHART_VERSION)"' deploy/porkbun-webhook/Chart.yaml
	helm unittest -u deploy/porkbun-webhook/
