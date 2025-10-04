# Setup Instructions

## 📁 Directory Structure

```
task-tracker/
├── cmd/
│   ├── task-tracker/
│   │   └── main.go          # Rename from root main.go
│   └── monitor-helper/
│       └── main.go          # Rename from monitor-helper.go
├── go.mod
├── go.sum                    # Auto-generated
├── Makefile                  # Updated
├── README.md
├── LICENSE
├── .gitignore
├── .env.example
├── quickstart.sh             # Updated
├── quickstart.ps1            # Updated
├── monitor_presets.json
├── bin/                      # Build output
├── docs/
│   ├── BUILDING.md
│   ├── API.md
│   └── CONTRIBUTING.md
└── task_captures/            # Runtime data
```

## 🔧 Setup Steps

### 1. Create Directory Structure

```bash
mkdir -p task-tracker/cmd/task-tracker
mkdir -p task-tracker/cmd/monitor-helper
mkdir -p task-tracker/docs
cd task-tracker
```

### 2. Place Files

**Root directory:**
- `go.mod`
- `Makefile` (updated version)
- `README.md`
- `LICENSE`
- `.gitignore`
- `.env.example`
- `quickstart.sh` (updated version)
- `quickstart.ps1` (updated version)
- `monitor_presets.json` (optional)

**cmd/task-tracker/ directory:**
- `main.go` (the task tracker code)

**cmd/monitor-helper/ directory:**
- `main.go` (the monitor helper code - previously monitor-helper.go)

**docs/ directory:**
- `BUILDING.md`
- `API.md`
- `CONTRIBUTING.md`

### 3. Build Commands

```bash
# Using Makefile (recommended)
make build

# Or manually
go build -o bin/task-tracker cmd/task-tracker/main.go
go build -o bin/monitor-helper cmd/monitor-helper/main.go

# Cross-compile for Windows
GOOS=windows GOARCH=amd64 go build -o bin/task-tracker.exe cmd/task-tracker/main.go
GOOS=windows GOARCH=amd64 go build -o bin/monitor-helper.exe cmd/monitor-helper/main.go
```

## ✅ Quick Setup Script

**Linux/Mac:**
```bash
#!/bin/bash
# setup.sh

# Create structure
mkdir -p cmd/task-tracker cmd/monitor-helper docs bin

# Move files (if you have them in root)
# mv main.go cmd/task-tracker/
# mv monitor-helper.go cmd/monitor-helper/main.go

# Install dependencies
go mod download
go mod tidy

# Build
go build -o bin/task-tracker cmd/task-tracker/main.go
go build -o bin/monitor-helper cmd/monitor-helper/main.go

echo "✅ Setup complete!"
echo "Binaries: ./bin/task-tracker and ./bin/monitor-helper"
```

**Windows (PowerShell):**
```powershell
# setup.ps1

# Create structure
New-Item -ItemType Directory -Force -Path "cmd/task-tracker"
New-Item -ItemType Directory -Force -Path "cmd/monitor-helper"
New-Item -ItemType Directory -Force -Path "docs"
New-Item -ItemType Directory -Force -Path "bin"

# Install dependencies
go mod download
go mod tidy

# Build
go build -o bin/task-tracker.exe cmd/task-tracker/main.go
go build -o bin/monitor-helper.exe cmd/monitor-helper/main.go

Write-Host "✅ Setup complete!"
Write-Host "Binaries: .\bin\task-tracker.exe and .\bin\monitor-helper.exe"
```

## 📋 File Placement Checklist

### Root Directory
- [ ] go.mod
- [ ] Makefile
- [ ] README.md
- [ ] LICENSE
- [ ] .gitignore
- [ ] .env.example
- [ ] quickstart.sh
- [ ] quickstart.ps1
- [ ] monitor_presets.json

### cmd/task-tracker/
- [ ] main.go (task tracker application)

### cmd/monitor-helper/
- [ ] main.go (monitor helper - rename from monitor-helper.go)

### docs/
- [ ] BUILDING.md
- [ ] API.md
- [ ] CONTRIBUTING.md

## 🚀 Test the Build

```bash
# Build
make build

# Test task-tracker
./bin/task-tracker --help

# Test monitor-helper
./bin/monitor-helper --help

# Try it out
export ANTHROPIC_API_KEY="your-key"
./bin/monitor-helper detect
./bin/task-tracker start "Test" --monitors all
# Press Ctrl+C after a few seconds
```

## 🔄 If You Already Have Files in Root

```bash
# Create new structure
mkdir -p cmd/task-tracker cmd/monitor-helper

# Move files
mv main.go cmd/task-tracker/
mv monitor-helper.go cmd/monitor-helper/main.go

# Rebuild
make build
```

## 💡 Alternative: Single Binary (Advanced)

If you want a single binary with subcommands instead:

```go
// In a single main.go
var rootCmd = &cobra.Command{Use: "task-tracker"}
var trackerCmd = &cobra.Command{Use: "track", ...}
var helperCmd = &cobra.Command{Use: "helper", ...}

rootCmd.AddCommand(trackerCmd)
rootCmd.AddCommand(helperCmd)
```

But the separate binaries approach is cleaner and more flexible.

## ✅ Final Directory Tree

```
task-tracker/
├── cmd/
│   ├── task-tracker/
│   │   └── main.go              ← Task tracker code
│   └── monitor-helper/
│       └── main.go              ← Monitor helper code
├── docs/
│   ├── BUILDING.md
│   ├── API.md
│   └── CONTRIBUTING.md
├── bin/                         ← Build output (gitignored)
│   ├── task-tracker
│   └── monitor-helper
├── task_captures/               ← Runtime (gitignored)
├── go.mod
├── go.sum
├── Makefile
├── README.md
├── LICENSE
├── .gitignore
├── .env.example
├── quickstart.sh
├── quickstart.ps1
└── monitor_presets.json
```

This is the standard Go project layout for multiple binaries! 🎉