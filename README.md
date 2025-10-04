# 📸 Task Tracker

> AI-powered task tracking with automatic screen capture and intelligent summarization

Cross-platform tool that captures your screen while you work, then uses Claude AI to generate detailed summaries for your Jira tasks.

## ✨ Features

- 🖥️ **Multi-monitor support** - Capture all monitors or specific ones
- 🤖 **AI-powered summaries** - Analyze screenshots locally with Claude Code
- ⏱️ **Automatic capture** - Set interval (default: 30 seconds)
- 📊 **Detailed metadata** - Track duration, monitor usage, and timestamps
- 🔄 **Cross-platform** - Works on Linux, Windows, and macOS
- 💾 **Local-first** - All screenshots and analysis stay on your machine
- 📝 **Review files** - Generates markdown files ready for Claude Code analysis

## 🚀 Quick Start

### Installation

**Download Pre-built Binaries** (coming soon):
```bash
# Linux
wget https://github.com/yourusername/task-tracker/releases/latest/download/task-tracker-linux-amd64.tar.gz
tar -xzf task-tracker-linux-amd64.tar.gz
sudo mv task-tracker monitor-helper /usr/local/bin/

# Windows (PowerShell)
Invoke-WebRequest -Uri "https://github.com/yourusername/task-tracker/releases/latest/download/task-tracker-windows-amd64.zip" -OutFile "task-tracker.zip"
Expand-Archive task-tracker.zip
```

**Or Build from Source**:
```bash
# Clone repository
git clone https://github.com/yourusername/task-tracker.git
cd task-tracker

# Build for your platform
make build

# Or build for all platforms
make build-all

# Install to system
make install
```

### Configuration

No configuration needed! Task Tracker works out of the box.

For AI analysis, you'll use Claude Code locally after capture is complete.

### First Run

1. **Detect your monitors**:
```bash
monitor-helper detect
```

2. **Run setup wizard** (recommended for multi-monitor setups):
```bash
monitor-helper setup
```

3. **Start tracking**:
```bash
task-tracker start "Implement login feature"
```

4. Work on your task, press `Ctrl+C` when done

5. **Analyze with Claude Code**:
```bash
claude-code task_captures/[session_id]/review.md
```

6. Get your AI summary! 🎉

## 📖 Usage

### Basic Commands

**Start tracking:**
```bash
task-tracker start "Task description"
```

**Stop tracking:**
- Press `Ctrl+C` - **This is the recommended way!**
- The tool will automatically:
  - Stop capturing
  - Save metadata.json
  - Generate review.md file with screenshots
  - Display instructions for Claude Code analysis

**Note:** Ctrl+C is handled gracefully - your data is safe!

**Capture specific monitors:**
```bash
task-tracker start "Code review" --monitors 1,2
task-tracker start "Meeting notes" --monitors primary
```

**Custom capture interval:**
```bash
task-tracker start "Bug fix" --interval 60  # Capture every 60 seconds
```

**Generate review file for existing session:**
```bash
task-tracker analyze 20240104_143022
```

**Analyze with Claude Code:**
```bash
# After generating review file
claude-code task_captures/20240104_143022/review.md
```

### Monitor Helper Commands

**Detect all monitors:**
```bash
monitor-helper detect
```

**Test capture a specific monitor:**
```bash
monitor-helper test 2
```

**Test all monitors:**
```bash
monitor-helper test-all
```

**Create monitor preset:**
```bash
monitor-helper preset coding 1,2 "Code editor and browser"
```

**List saved presets:**
```bash
monitor-helper list
```

**Interactive setup:**
```bash
monitor-helper setup
```

## 🖥️ Multi-Monitor Examples

### Development Workflow
```bash
# Code on monitor 1, docs on monitor 2
task-tracker start "API implementation" --monitors 1,2
```

### Design Workflow
```bash
# Design tool on all monitors
task-tracker start "UI mockups" --monitors all
```

### Meeting Workflow
```bash
# Only capture your notes screen
task-tracker start "Sprint planning" --monitors 1
```

### Testing Workflow
```bash
# Code, browser, and terminal
task-tracker start "E2E testing" --monitors 1,2,3
```

## 📁 Output Structure

```
task_captures/
└── 20240104_143022/
    ├── screen_m1_143022.png    # Monitor 1
    ├── screen_m1_143052.png
    ├── screen_m2_143022.png    # Monitor 2
    ├── screen_m2_143052.png
    ├── metadata.json            # Session info
    └── review.md                # Review file for Claude Code analysis
```

## 🔨 Building

### Prerequisites

**Linux (Ubuntu/Debian)**:
```bash
sudo apt-get install golang-go libx11-dev xorg-dev libxtst-dev
```

**Windows**:
- Install Go from https://golang.org/dl/

**macOS**:
```bash
brew install go
```

### Build Commands

```bash
# Build for current platform
make build

# Build for specific platform
make build-linux
make build-windows
make build-darwin

# Build for all platforms
make build-all

# Install to system
make install

# Create release packages
make package

# Run tests
make test

# Show all options
make help
```

### Manual Build

```bash
# Linux
go build -o task-tracker main.go
go build -o monitor-helper monitor-helper.go

# Windows (cross-compile from Linux)
GOOS=windows GOARCH=amd64 go build -o task-tracker.exe main.go
GOOS=windows GOARCH=amd64 go build -o monitor-helper.exe monitor-helper.go

# Windows (on Windows)
go build -o task-tracker.exe main.go
go build -o monitor-helper.exe monitor-helper.go
```

## ⚙️ Configuration

### Environment Variables

No environment variables required! Task Tracker works completely offline.

Optional (for future features):
- `JIRA_URL` - Your Jira instance URL
- `JIRA_API_TOKEN` - Your Jira API token

### Command-Line Options

**task-tracker start:**
- `--monitors, -m` - Which monitors to capture (default: "all")
  - Options: `all`, `primary`, `1`, `1,2`, `2,3`, etc.
- `--interval, -i` - Capture interval in seconds (default: 30)

## 🤖 AI Analysis with Claude Code

After capture, Task Tracker generates a `review.md` file containing:
- Session metadata (task name, duration, screenshot count)
- Sampled screenshots with timestamps
- Analysis prompt for Claude

**How to analyze:**

1. **Capture your work session:**
   ```bash
   task-tracker start "Implement authentication"
   # Work... then Ctrl+C
   ```

2. **Open in Claude Code:**
   ```bash
   claude-code task_captures/[session_id]/review.md
   ```

3. **Claude will analyze and provide:**
   - What was accomplished
   - Key activities observed
   - Technologies and tools used
   - How different monitors/windows were used
   - Work progression over time
   - Suggested Jira summary (2-3 sentences)

**Why Claude Code?**
- ✅ **Local analysis** - No API calls, complete privacy
- ✅ **Interactive** - Ask follow-up questions
- ✅ **Context-aware** - Claude can see your full codebase
- ✅ **Free** - No API costs

## 📊 Use Cases

### 1. Track Development Work
```bash
task-tracker start "Implement payment gateway" --monitors 1,2 --interval 45
```

### 2. Document Bug Fixes
```bash
task-tracker start "Fix memory leak in user service" --monitors all
```

### 3. Record Meeting Notes
```bash
task-tracker start "Product roadmap meeting" --monitors primary --interval 60
```

### 4. Design Sessions
```bash
task-tracker start "Landing page redesign" --monitors all --interval 30
```

### 5. Learning & Research
```bash
task-tracker start "Learn React Hooks" --monitors 1,2
```

## 🔐 Privacy & Security

- **100% Local**: All screenshots stored locally on your machine
- **No API calls**: Analysis happens in Claude Code locally
- **Monitor selection**: Capture only the monitors you want
- **Manual control**: You decide when to start and stop
- **Your data stays yours**: Nothing is sent to external servers

### Privacy Best Practices

1. **Don't capture sensitive monitors**: Use `--monitors` to exclude screens with sensitive data
2. **Review before analysis**: Check screenshots before opening in Claude Code
3. **Clean up**: Regularly delete old capture sessions
4. **Encrypt sensitive sessions**: Use tools like `age` or `gpg` to encrypt folders

## 🛠️ Troubleshooting

### Linux Issues

**"Failed to capture display":**
```bash
# Install X11 dependencies
sudo apt-get install libx11-dev xorg-dev libxtst-dev

# If using Wayland, switch to X11 or use XWayland
```

**"Permission denied":**
```bash
chmod +x task-tracker monitor-helper
```

### Windows Issues

**Slow capture:**
- This is normal on Windows (GDI+ is slower)
- Increase interval: `--interval 60`

**Antivirus blocking:**
- Add exception for task-tracker.exe
- Some antivirus software flags screen capture as suspicious

### macOS Issues

**"Screen Recording permission required":**
1. Go to System Preferences → Security & Privacy
2. Privacy → Screen Recording
3. Add Terminal or your terminal app

### General Issues

**High disk usage:**
- Screenshots are compressed PNGs
- Reduce capture frequency
- Capture fewer monitors
- Clean old sessions regularly

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Run `make fmt` and `make test`
6. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [kbinani/screenshot](https://github.com/kbinani/screenshot) - Cross-platform screenshot library
- [spf13/cobra](https://github.com/spf13/cobra) - CLI framework
- [Anthropic](https://www.anthropic.com/) - Claude AI API

## 📞 Support

- 📖 Documentation: [GitHub Wiki](https://github.com/yourusername/task-tracker/wiki)
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/task-tracker/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/yourusername/task-tracker/discussions)

## 🗺️ Roadmap

- [ ] Web dashboard for viewing sessions
- [ ] OCR for text extraction from screenshots
- [ ] Activity detection (pause during idle)
- [ ] Video export (timelapse generation)
- [ ] Cloud sync (S3, Google Drive)
- [ ] Slack integration
- [ ] Browser extension for web-based tracking
- [ ] Team collaboration features
- [ ] Mobile companion app

---

**Made with ❤️ for developers who want better task documentation**