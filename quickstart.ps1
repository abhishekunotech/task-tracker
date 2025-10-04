# Task Tracker - Quick Start Script for Windows
# Run with: powershell -ExecutionPolicy Bypass -File quickstart.ps1

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  📸 Task Tracker - Quick Start Setup (Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Step 1: Check for Go installation
Write-Host "Step 1: Checking for Go installation..." -ForegroundColor Yellow

if (Get-Command go -ErrorAction SilentlyContinue) {
    $goVersion = go version
    Write-Host "✅ Go is installed: $goVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Go is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installing Go..." -ForegroundColor Yellow
    
    # Download Go installer
    $goVersion = "1.21.6"
    $goInstaller = "go$goVersion.windows-amd64.msi"
    $downloadUrl = "https://go.dev/dl/$goInstaller"
    
    Write-Host "Downloading Go $goVersion..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $goInstaller
    
    Write-Host "Installing Go (this will open the installer)..."
    Start-Process msiexec.exe -ArgumentList "/i $goInstaller /quiet" -Wait
    
    # Clean up
    Remove-Item $goInstaller
    
    # Refresh environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host "✅ Go installed successfully" -ForegroundColor Green
    Write-Host "⚠️  You may need to restart PowerShell for Go to be available" -ForegroundColor Yellow
}

# Step 2: Build the project
Write-Host ""
Write-Host "Step 2: Building Task Tracker..." -ForegroundColor Yellow

if (-not (Test-Path "go.mod")) {
    Write-Host "❌ go.mod not found. Are you in the project directory?" -ForegroundColor Red
    exit 1
}

Write-Host "Installing Go dependencies..."
go mod download
go mod tidy

Write-Host "Building binaries..."
New-Item -ItemType Directory -Force -Path "bin" | Out-Null
go build -ldflags "-s -w" -o bin/task-tracker.exe main.go
go build -ldflags "-s -w" -o bin/monitor-helper.exe monitor-helper.go

Write-Host "✅ Build complete!" -ForegroundColor Green

# Step 3: Installation
Write-Host ""
Write-Host "Step 3: Installation" -ForegroundColor Yellow
Write-Host "Where would you like to install?"
Write-Host "  1) Add to System PATH (recommended)"
Write-Host "  2) Add to User PATH"
Write-Host "  3) Skip installation (use from .\bin\)"
Write-Host ""

$choice = Read-Host "Choice [1-3]"

switch ($choice) {
    "1" {
        if (-not $isAdmin) {
            Write-Host "❌ System PATH requires Administrator privileges" -ForegroundColor Red
            Write-Host "Please run this script as Administrator or choose option 2" -ForegroundColor Yellow
            $installPath = (Get-Location).Path + "\bin"
        } else {
            $installDir = "C:\Program Files\TaskTracker"
            Write-Host "Installing to $installDir..."
            
            New-Item -ItemType Directory -Force -Path $installDir | Out-Null
            Copy-Item "bin\task-tracker.exe" "$installDir\"
            Copy-Item "bin\monitor-helper.exe" "$installDir\"
            
            # Add to System PATH
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            if ($currentPath -notlike "*$installDir*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "Machine")
                Write-Host "✅ Added to System PATH" -ForegroundColor Green
            }
            
            $installPath = $installDir
            Write-Host "✅ Installed to $installDir" -ForegroundColor Green
        }
    }
    "2" {
        $installDir = "$env:USERPROFILE\AppData\Local\TaskTracker"
        Write-Host "Installing to $installDir..."
        
        New-Item -ItemType Directory -Force -Path $installDir | Out-Null
        Copy-Item "bin\task-tracker.exe" "$installDir\"
        Copy-Item "bin\monitor-helper.exe" "$installDir\"
        
        # Add to User PATH
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
            Write-Host "✅ Added to User PATH" -ForegroundColor Green
        }
        
        $installPath = $installDir
        Write-Host "✅ Installed to $installDir" -ForegroundColor Green
    }
    default {
        Write-Host "Skipping installation. Binaries are in .\bin\" -ForegroundColor Yellow
        $installPath = (Get-Location).Path + "\bin"
    }
}

# Refresh PATH for current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 4: Configure API key
Write-Host ""
Write-Host "Step 4: Configure Anthropic API Key" -ForegroundColor Yellow
Write-Host "Do you have an Anthropic API key?"
$apiKey = Read-Host "Enter API key (or press Enter to skip)"

if ($apiKey) {
    # Set User environment variable
    [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
    $env:ANTHROPIC_API_KEY = $apiKey
    
    Write-Host "✅ API key saved to environment variables" -ForegroundColor Green
    Write-Host "⚠️  You may need to restart PowerShell for the variable to be available" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Skipping API key setup" -ForegroundColor Yellow
    Write-Host "You can add it later with:"
    Write-Host '  $env:ANTHROPIC_API_KEY="your-key-here"' -ForegroundColor Gray
    Write-Host "Or set it permanently in System Environment Variables" -ForegroundColor Gray
}

# Step 5: Detect monitors
Write-Host ""
Write-Host "Step 5: Detect Monitors" -ForegroundColor Yellow
$detectMonitors = Read-Host "Would you like to detect your monitors now? (y/n)"

if ($detectMonitors -eq "y" -or $detectMonitors -eq "Y") {
    if ($installPath -like "*\bin") {
        & ".\bin\monitor-helper.exe" detect
    } else {
        & monitor-helper detect
    }
    
    Write-Host ""
    $runWizard = Read-Host "Run the interactive setup wizard? (y/n)"
    
    if ($runWizard -eq "y" -or $runWizard -eq "Y") {
        if ($installPath -like "*\bin") {
            & ".\bin\monitor-helper.exe" setup
        } else {
            & monitor-helper setup
        }
    }
}

# Step 6: Create desktop shortcut
Write-Host ""
Write-Host "Step 6: Create Desktop Shortcut (optional)" -ForegroundColor Yellow
$createShortcut = Read-Host "Create desktop shortcut? (y/n)"

if ($createShortcut -eq "y" -or $createShortcut -eq "Y") {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Task Tracker.lnk")
    
    if ($installPath -like "*\bin") {
        $Shortcut.TargetPath = "$installPath\task-tracker.exe"
    } else {
        $Shortcut.TargetPath = "task-tracker.exe"
    }
    
    $Shortcut.Arguments = 'start --monitors all'
    $Shortcut.WorkingDirectory = $env:USERPROFILE
    $Shortcut.Description = "AI-powered task tracking with screen capture"
    $Shortcut.Save()
    
    Write-Host "✅ Desktop shortcut created" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  ✅ Setup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation Summary:" -ForegroundColor Green
Write-Host "  • Binaries location: $installPath"
Write-Host "  • Task Tracker: $installPath\task-tracker.exe"
Write-Host "  • Monitor Helper: $installPath\monitor-helper.exe"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host ""
Write-Host "1. If you added API key or installed to PATH, restart PowerShell"
Write-Host ""
Write-Host "2. Try it out:"
if ($installPath -like "*\bin") {
    Write-Host "   .\bin\task-tracker.exe start `"Test task`" --monitors all" -ForegroundColor Cyan
} else {
    Write-Host "   task-tracker start `"Test task`" --monitors all" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "3. Get help:"
if ($installPath -like "*\bin") {
    Write-Host "   .\bin\task-tracker.exe --help" -ForegroundColor Cyan
    Write-Host "   .\bin\monitor-helper.exe --help" -ForegroundColor Cyan
} else {
    Write-Host "   task-tracker --help" -ForegroundColor Cyan
    Write-Host "   monitor-helper --help" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Green
if ($installPath -like "*\bin") {
    Write-Host "  .\bin\monitor-helper.exe detect       # Detect monitors" -ForegroundColor Cyan
    Write-Host "  .\bin\monitor-helper.exe setup        # Interactive setup" -ForegroundColor Cyan
    Write-Host "  .\bin\task-tracker.exe start 'Task'   # Start tracking" -ForegroundColor Cyan
} else {
    Write-Host "  monitor-helper detect       # Detect monitors" -ForegroundColor Cyan
    Write-Host "  monitor-helper setup        # Interactive setup" -ForegroundColor Cyan
    Write-Host "  task-tracker start 'Task'   # Start tracking" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  README.md for full documentation"
Write-Host "  https://docs.anthropic.com for Claude API"
Write-Host ""
Write-Host "Happy tracking! 🚀" -ForegroundColor Green
Write-Host ""