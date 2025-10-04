# Building Task Tracker

This guide covers building Task Tracker from source for different platforms.

## Prerequisites

### All Platforms
- Go 1.21 or later
- Git (for cloning)

### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y golang-go libx11-dev xorg-dev libxtst-dev build-essential
```

### Linux (Fedora/RHEL)
```bash
sudo dnf install -y golang libX11-devel libXtst-devel
```

### Linux (Arch)
```bash
sudo pacman -S go libx11 libxtst
```

### Windows
- Install Go from https://golang.org/dl/
- No additional dependencies required

### macOS
```bash
brew install go
```

## Quick Build

### Using Makefile (Recommended)

```bash
# Build for current platform
make build

# Build for all platforms
make build-all

# Build for specific platform
make build-linux
make build-windows
make build-darwin
```

### Manual Build

```bash
# Clone repository
git clone https://github.com/yourusername/task-tracker.git
cd task-tracker

# Download dependencies
go mod download
go mod tidy

# Build for current platform
go build -o task-tracker main.go
go build -o monitor-helper monitor-helper.go

# Cross-compile for Windows (from Linux/Mac)
GOOS=windows GOARCH=amd64 go build -o task-tracker.exe main.go
GOOS=windows GOARCH=amd64 go build -o monitor-helper.exe monitor-helper.go

# Cross-compile for Linux (from Windows/Mac)
GOOS=linux GOARCH=amd64 go build -o task-tracker-linux main.go
GOOS=linux GOARCH=amd64 go build -o monitor-helper-linux monitor-helper.go
```

## Build Options

### Optimized Build (Smaller Binary)

```bash
# Strip debug info and symbols
go build -ldflags="-s -w" -o task-tracker main.go

# Further compress with UPX (optional)
upx --best --lzma task-tracker
```

### Build with Version Info

```bash
VERSION=1.0.0
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(git rev-parse --short HEAD)

go build -ldflags="-s -w -X main.Version=$VERSION -X main.BuildTime=$BUILD_TIME -X main.GitCommit=$GIT_COMMIT" -o task-tracker main.go
```

### Static Build (No Dynamic Libraries)

```bash
# Linux
CGO_ENABLED=0 go build -a -installsuffix cgo -o task-tracker main.go

# Note: This may not work for screenshot library which requires CGO
```

## Platform-Specific Notes

### Linux

**Wayland Support:**
- The screenshot library works best with X11
- On Wayland systems, ensure XWayland is running
- Check with: `echo $XDG_SESSION_TYPE`

**Permissions:**
- Some systems may require additional permissions for screen capture
- Run with appropriate user permissions

### Windows

**Windows Defender:**
- May flag the binary as suspicious (false positive)
- Add exception if needed: Windows Security → Virus & threat protection → Exclusions

**Build Time:**
- Windows builds may take longer due to GDI+ dependencies
- Cross-compilation from Linux is faster

### macOS

**Screen Recording Permission:**
- macOS requires explicit permission for screen recording
- Grant permission in: System Preferences → Security & Privacy → Privacy → Screen Recording

**Apple Silicon (M1/M2):**
```bash
# Build for ARM64
GOOS=darwin GOARCH=arm64 go build -o task-tracker-arm64 main.go

# Build universal binary (requires macOS)
lipo -create -output task-tracker task-tracker-amd64 task-tracker-arm64
```

## Troubleshooting

### "cannot find package"

```bash
# Clean module cache
go clean -modcache

# Re-download dependencies
go mod download
go mod tidy
```

### "undefined reference" or "linker errors" (Linux)

```bash
# Install missing development libraries
sudo apt-get install libx11-dev xorg-dev libxtst-dev

# Verify CGO is enabled
go env CGO_ENABLED  # Should show "1"
```

### Build fails on Windows

```bash
# Ensure Go is in PATH
go version

# If not, add Go to PATH:
# C:\Go\bin (or wherever Go is installed)
```

### Cross-compilation issues

```bash
# Disable CGO for pure Go build (may lose some features)
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build main.go

# Note: Screenshot library requires CGO, so this won't work for task-tracker
# Better to build natively on each platform
```

## Build Artifacts

After building, you'll have:

```
bin/
├── task-tracker          # Linux/Mac binary
├── task-tracker.exe      # Windows binary
├── monitor-helper        # Linux/Mac helper
└── monitor-helper.exe    # Windows helper
```

## CI/CD Build

### GitHub Actions Example

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Install Linux dependencies
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y libx11-dev xorg-dev libxtst-dev
      
      - name: Build
        run: |
          go mod download
          go build -o task-tracker main.go
          go build -o monitor-helper monitor-helper.go
      
      - name: Test
        run: go test -v ./...
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: binaries-${{ matrix.os }}
          path: |
            task-tracker*
            monitor-helper*
```

## Development Build

For rapid development:

```bash
# Watch for changes and rebuild (requires entr)
ls *.go | entr -r make build

# Or use go run for quick testing
go run main.go start "Test task"
```

## Release Build

```bash
# Build all platforms with version
make VERSION=1.0.0 build-all

# Create release packages
make package

# Results in releases/ directory:
# - task-tracker-v1.0.0-linux-amd64.tar.gz
# - task-tracker-v1.0.0-windows-amd64.zip
# - task-tracker-v1.0.0-darwin-amd64.tar.gz
# - task-tracker-v1.0.0-darwin-arm64.tar.gz
```

## Verification

After building, verify the binaries:

```bash
# Check binary works
./task-tracker --help
./monitor-helper --help

# Check version (if built with version info)
./task-tracker version

# Test basic functionality
./task-tracker start "Test" --monitors primary
# Press Ctrl+C after a few seconds

# Verify session was created
ls task_captures/
```

## Next Steps

- See [README.md](../README.md) for usage instructions
- See [API.md](API.md) for Claude API integration details
- See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines