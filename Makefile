# Task Tracker - Makefile
# Cross-platform build automation

# Binary names
BINARY_NAME=task-tracker
HELPER_NAME=monitor-helper

# Build directory
BUILD_DIR=bin

# Version info
VERSION?=1.0.0
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Build flags
LDFLAGS=-ldflags "-s -w -X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.GitCommit=$(GIT_COMMIT)"

.PHONY: all build clean test deps help install

# Default target
all: deps build

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Build for current platform
build: deps
	@echo "🔨 Building for current platform..."
	@mkdir -p $(BUILD_DIR)
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) cmd/task-tracker/main.go
	$(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(HELPER_NAME) cmd/monitor-helper/main.go
	@echo "✅ Build complete! Binaries in $(BUILD_DIR)/"

# Build for Linux (AMD64)
build-linux:
	@echo "🐧 Building for Linux (amd64)..."
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 cmd/task-tracker/main.go
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(HELPER_NAME)-linux-amd64 cmd/monitor-helper/main.go
	@echo "✅ Linux build complete!"

# Build for Windows (AMD64)
build-windows:
	@echo "🪟 Building for Windows (amd64)..."
	@mkdir -p $(BUILD_DIR)
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe cmd/task-tracker/main.go
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(HELPER_NAME)-windows-amd64.exe cmd/monitor-helper/main.go
	@echo "✅ Windows build complete!"

# Build for macOS (AMD64)
build-darwin:
	@echo "🍎 Building for macOS (amd64)..."
	@mkdir -p $(BUILD_DIR)
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 cmd/task-tracker/main.go
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(HELPER_NAME)-darwin-amd64 cmd/monitor-helper/main.go
	@echo "✅ macOS build complete!"

# Build for macOS (ARM64 - Apple Silicon)
build-darwin-arm:
	@echo "🍎 Building for macOS (arm64)..."
	@mkdir -p $(BUILD_DIR)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 cmd/task-tracker/main.go
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(LDFLAGS) -o $(BUILD_DIR)/$(HELPER_NAME)-darwin-arm64 cmd/monitor-helper/main.go
	@echo "✅ macOS ARM64 build complete!"

# Build for all platforms
build-all: build-linux build-windows build-darwin build-darwin-arm
	@echo "🎉 All platform builds complete!"
	@ls -lh $(BUILD_DIR)/

# Run tests
test:
	@echo "🧪 Running tests..."
	$(GOTEST) -v ./...

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)
	rm -f test_monitor_*.png
	@echo "✅ Clean complete!"

# Install to system (Unix-like systems)
install: build
	@echo "📥 Installing to /usr/local/bin..."
	sudo cp $(BUILD_DIR)/$(BINARY_NAME) /usr/local/bin/
	sudo cp $(BUILD_DIR)/$(HELPER_NAME) /usr/local/bin/
	@echo "✅ Installation complete!"

# Install to user bin (no sudo required)
install-user: build
	@echo "📥 Installing to ~/.local/bin..."
	@mkdir -p ~/.local/bin
	cp $(BUILD_DIR)/$(BINARY_NAME) ~/.local/bin/
	cp $(BUILD_DIR)/$(HELPER_NAME) ~/.local/bin/
	@echo "✅ Installation complete!"
	@echo "💡 Make sure ~/.local/bin is in your PATH"

# Uninstall from system
uninstall:
	@echo "🗑️  Uninstalling..."
	sudo rm -f /usr/local/bin/$(BINARY_NAME)
	sudo rm -f /usr/local/bin/$(HELPER_NAME)
	@echo "✅ Uninstall complete!"

# Create release packages
package: build-all
	@echo "📦 Creating release packages..."
	@mkdir -p releases
	
	# Linux package
	tar -czf releases/$(BINARY_NAME)-v$(VERSION)-linux-amd64.tar.gz \
		-C $(BUILD_DIR) $(BINARY_NAME)-linux-amd64 $(HELPER_NAME)-linux-amd64 \
		-C .. README.md
	
	# Windows package
	cd $(BUILD_DIR) && zip ../releases/$(BINARY_NAME)-v$(VERSION)-windows-amd64.zip \
		$(BINARY_NAME)-windows-amd64.exe $(HELPER_NAME)-windows-amd64.exe
	
	# macOS package (amd64)
	tar -czf releases/$(BINARY_NAME)-v$(VERSION)-darwin-amd64.tar.gz \
		-C $(BUILD_DIR) $(BINARY_NAME)-darwin-amd64 $(HELPER_NAME)-darwin-amd64 \
		-C .. README.md
	
	# macOS package (arm64)
	tar -czf releases/$(BINARY_NAME)-v$(VERSION)-darwin-arm64.tar.gz \
		-C $(BUILD_DIR) $(BINARY_NAME)-darwin-arm64 $(HELPER_NAME)-darwin-arm64 \
		-C .. README.md
	
	@echo "✅ Release packages created in releases/"
	@ls -lh releases/

# Run the application
run: build
	@echo "🚀 Running task-tracker..."
	./$(BUILD_DIR)/$(BINARY_NAME) start "Test Task" --monitors all

# Run monitor helper
run-helper: build
	@echo "🚀 Running monitor-helper..."
	./$(BUILD_DIR)/$(HELPER_NAME) detect

# Development mode with auto-rebuild (requires entr)
dev:
	@echo "🔄 Development mode - watching for changes..."
	ls *.go | entr -r make run

# Format code
fmt:
	@echo "🎨 Formatting code..."
	$(GOCMD) fmt ./...
	@echo "✅ Formatting complete!"

# Lint code (requires golangci-lint)
lint:
	@echo "🔍 Linting code..."
	golangci-lint run
	@echo "✅ Linting complete!"

# Show help
help:
	@echo "Task Tracker - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make              - Build for current platform"
	@echo "  make build        - Build for current platform"
	@echo "  make build-linux  - Build for Linux (amd64)"
	@echo "  make build-windows - Build for Windows (amd64)"
	@echo "  make build-darwin - Build for macOS (amd64)"
	@echo "  make build-darwin-arm - Build for macOS (arm64)"
	@echo "  make build-all    - Build for all platforms"
	@echo "  make test         - Run tests"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make install      - Install to /usr/local/bin (requires sudo)"
	@echo "  make install-user - Install to ~/.local/bin"
	@echo "  make uninstall    - Uninstall from /usr/local/bin"
	@echo "  make package      - Create release packages"
	@echo "  make run          - Build and run"
	@echo "  make run-helper   - Build and run monitor helper"
	@echo "  make fmt          - Format code"
	@echo "  make lint         - Lint code"
	@echo "  make deps         - Install dependencies"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Environment variables:"
	@echo "  VERSION           - Set version (default: 1.0.0)"
	@echo ""
	@echo "Example:"
	@echo "  make VERSION=1.2.0 build-all"