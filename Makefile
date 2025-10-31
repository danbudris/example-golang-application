.PHONY: help build clean test run docker-build docker-run k8s-manifests all

# Build configuration
APP_NAME := example-golang-application
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Go configuration
GO := go
GO_VERSION := $(shell $(GO) version | awk '{print $$3}')
LDFLAGS := -X main.Version=$(VERSION) \
           -X main.BuildTime=$(BUILD_TIME) \
           -X main.GitCommit=$(GIT_COMMIT)

# Docker configuration
DOCKER_IMAGE := $(APP_NAME)
DOCKER_TAG := $(VERSION)
DOCKER_REGISTRY := localhost:5000

# Kubernetes configuration
K8S_NAMESPACE := default
K8S_APP_NAME := $(APP_NAME)

# Build targets
OS_ARCH := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64 windows/arm64

help: ## Display this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

build: ## Build binary for current platform
	@echo "Building for $(shell go env GOOS)/$(shell go env GOARCH)..."
	@mkdir -p bin
	@$(GO) build -ldflags "$(LDFLAGS)" -o bin/$(APP_NAME) ./cmd/server
	@echo "Binary created: bin/$(APP_NAME)"

build-all: clean ## Build binaries for all supported platforms
	@echo "Building for all platforms..."
	@mkdir -p bin
	@for platform in $(OS_ARCH); do \
		OS=$$(echo $$platform | cut -d'/' -f1); \
		ARCH=$$(echo $$platform | cut -d'/' -f2); \
		OUTPUT="bin/$(APP_NAME)-$$OS-$$ARCH"; \
		if [ "$$OS" = "windows" ]; then \
			OUTPUT="$$OUTPUT.exe"; \
		fi; \
		echo "Building $$OS/$$ARCH -> $$OUTPUT"; \
		GOOS=$$OS GOARCH=$$ARCH $(GO) build \
			-ldflags "$(LDFLAGS)" \
			-o $$OUTPUT ./cmd/server; \
	done
	@echo "Build complete. Binaries in bin/ directory"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf bin/
	@rm -rf dist/
	@rm -rf k8s/*.yaml
	@$(GO) clean -cache
	@echo "Clean complete"

test: ## Run tests
	@echo "Running tests..."
	@$(GO) test -v ./...

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	@$(GO) test -v -coverprofile=coverage.out ./...
	@$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

run: ## Run the application locally
	@echo "Running application..."
	@$(GO) run ./cmd/server

docker-build: build ## Build Docker image
	@echo "Building Docker image: $(DOCKER_IMAGE):$(DOCKER_TAG)"
	@docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest
	@echo "Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)"

docker-run: docker-build ## Run Docker container locally
	@echo "Running Docker container..."
	@docker run --rm -p 8080:8080 $(DOCKER_IMAGE):$(DOCKER_TAG)

docker-build-debug: ## Build Docker debug image with Delve
	@echo "Building Docker debug image: $(DOCKER_IMAGE):$(DOCKER_TAG)-debug"
	@docker build -f Dockerfile.debug -t $(DOCKER_IMAGE):$(DOCKER_TAG)-debug .
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG)-debug $(DOCKER_IMAGE):debug
	@echo "Docker debug image built: $(DOCKER_IMAGE):$(DOCKER_TAG)-debug"
	@echo "Port 8080: HTTP server"
	@echo "Port 2345: Delve debugger"

docker-run-debug: docker-build-debug ## Run Docker container in debug mode
	@echo "Running Docker container in debug mode..."
	@echo "HTTP server: http://localhost:8080"
	@echo "Delve debugger: localhost:2345"
	@echo "Attach VS Code debugger using 'Attach to Docker Container (Delve)' configuration"
	@docker run --rm -it \
		-p 8080:8080 \
		-p 2345:2345 \
		--security-opt="apparmor=unconfined" \
		--security-opt="seccomp=unconfined" \
		--cap-add=SYS_PTRACE \
		$(DOCKER_IMAGE):$(DOCKER_TAG)-debug

docker-debug: docker-run-debug ## Alias for docker-run-debug

docker-push: docker-build ## Push Docker image to registry
	@echo "Pushing Docker image to $(DOCKER_REGISTRY)..."
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):latest
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(DOCKER_TAG)
	@docker push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE):latest
	@echo "Docker image pushed"

k8s-manifests: ## Generate Kubernetes manifests
	@echo "Generating Kubernetes manifests..."
	@mkdir -p k8s
	@sed 's|{{APP_NAME}}|$(K8S_APP_NAME)|g; s|{{VERSION}}|$(DOCKER_TAG)|g; s|{{NAMESPACE}}|$(K8S_NAMESPACE)|g; s|{{DOCKER_IMAGE}}|$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)|g' \
		k8s/pod.yaml.template > k8s/pod.yaml 2>/dev/null || \
		cat k8s/pod.yaml.template | sed 's|{{APP_NAME}}|$(K8S_APP_NAME)|g; s|{{VERSION}}|$(DOCKER_TAG)|g; s|{{NAMESPACE}}|$(K8S_NAMESPACE)|g; s|{{DOCKER_IMAGE}}|$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)|g' > k8s/pod.yaml
	@sed 's|{{APP_NAME}}|$(K8S_APP_NAME)|g; s|{{VERSION}}|$(DOCKER_TAG)|g; s|{{NAMESPACE}}|$(K8S_NAMESPACE)|g; s|{{DOCKER_IMAGE}}|$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)|g' \
		k8s/deployment.yaml.template > k8s/deployment.yaml 2>/dev/null || \
		cat k8s/deployment.yaml.template | sed 's|{{APP_NAME}}|$(K8S_APP_NAME)|g; s|{{VERSION}}|$(DOCKER_TAG)|g; s|{{NAMESPACE}}|$(K8S_NAMESPACE)|g; s|{{DOCKER_IMAGE}}|$(DOCKER_REGISTRY)/$(DOCKER_IMAGE)|g' > k8s/deployment.yaml
	@echo "Kubernetes manifests generated in k8s/ directory"

all: clean build-all docker-build k8s-manifests ## Build everything: binaries, Docker image, and K8s manifests
	@echo "Complete build finished!"

.DEFAULT_GOAL := help
