BIN := estafette-gke-preemptible-killer
PKG := github.com/softonic/estafette-gke-preemptible-killer
VERSION ?= 0.0.10-dev
ARCH ?= amd64
APP ?= gke-preemptible-killer
NAMESPACE ?= gke-preemptible-killer
RELEASE_NAME ?= gke-preemptible-killer
KO_DOCKER_REPO = registry.softonic.io/gke-preemptible-killer
REPOSITORY ?= softonic/$(BIN)

IMAGE := softonic/$(BIN)

BUILD_IMAGE ?= golang:1.14-buster

ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif


.PHONY: all
all: dev

.PHONY: build
build:
	go mod download
	go build .
        
.PHONY: test
test:
	GOARCH=${ARCH} go test -v  ./...

.PHONY: image
image:
	docker build -t $(IMAGE):$(VERSION) -f Dockerfile .
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest

.PHONY: dev
dev: image
	kind load docker-image $(IMAGE):$(VERSION)

.PHONY: docker-push
docker-push:
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest
