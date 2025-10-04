// Task Tracker - Cross-platform screen capture and AI summarization
// Build: go build -o task-tracker main.go
// Linux: go build -o task-tracker-linux main.go
// Windows: GOOS=windows GOARCH=amd64 go build -o task-tracker.exe main.go

package main

import (
	"encoding/json"
	"fmt"
	"image/png"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/kbinani/screenshot"
	"github.com/spf13/cobra"
)

// Screenshot metadata
type Screenshot struct {
	Path         string  `json:"path"`
	Monitor      int     `json:"monitor"`
	Timestamp    string  `json:"timestamp"`
	RelativeTime float64 `json:"relative_time"`
	Resolution   string  `json:"resolution"`
}

// Session metadata
type SessionMetadata struct {
	SessionID       string       `json:"session_id"`
	TaskName        string       `json:"task_name"`
	StartTime       string       `json:"start_time"`
	EndTime         string       `json:"end_time"`
	DurationSeconds float64      `json:"duration_seconds"`
	ScreenshotCount int          `json:"screenshot_count"`
	Screenshots     []Screenshot `json:"screenshots"`
}

// TaskTracker main structure
type TaskTracker struct {
	OutputDir         string
	SessionID         string
	SessionDir        string
	TaskName          string
	Screenshots       []Screenshot
	IsCapturing       bool
	CaptureInterval   time.Duration
	MonitorsConfig    string
	MonitorsToCapture []int
	StartTime         time.Time
	EndTime           time.Time
}

// NewTaskTracker creates a new tracker instance
func NewTaskTracker(outputDir, monitors string) (*TaskTracker, error) {
	sessionID := time.Now().Format("20060102_150405")
	sessionDir := filepath.Join(outputDir, sessionID)

	if err := os.MkdirAll(sessionDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create session directory: %w", err)
	}

	tracker := &TaskTracker{
		OutputDir:       outputDir,
		SessionID:       sessionID,
		SessionDir:      sessionDir,
		Screenshots:     []Screenshot{},
		IsCapturing:     false,
		CaptureInterval: 30 * time.Second,
		MonitorsConfig:  monitors,
	}

	tracker.setupMonitors()
	return tracker, nil
}

// Setup monitors
func (t *TaskTracker) setupMonitors() {
	numMonitors := screenshot.NumActiveDisplays()
	fmt.Printf("\n🖥️  Detected %d monitor(s):\n", numMonitors)

	for i := 0; i < numMonitors; i++ {
		bounds := screenshot.GetDisplayBounds(i)
		fmt.Printf("  Monitor %d: %dx%d at (%d, %d)\n",
			i+1, bounds.Dx(), bounds.Dy(), bounds.Min.X, bounds.Min.Y)
	}

	// Parse monitor configuration
	t.MonitorsToCapture = []int{}

	switch t.MonitorsConfig {
	case "all":
		for i := 0; i < numMonitors; i++ {
			t.MonitorsToCapture = append(t.MonitorsToCapture, i)
		}
		fmt.Printf("📸 Will capture: ALL monitors\n")

	case "primary":
		t.MonitorsToCapture = []int{0}
		fmt.Printf("📸 Will capture: Primary monitor only\n")

	default:
		// Parse comma-separated list
		parts := strings.Split(t.MonitorsConfig, ",")
		for _, p := range parts {
			num, err := strconv.Atoi(strings.TrimSpace(p))
			if err == nil && num >= 1 && num <= numMonitors {
				t.MonitorsToCapture = append(t.MonitorsToCapture, num-1) // 0-indexed
			}
		}

		if len(t.MonitorsToCapture) == 0 {
			fmt.Printf("⚠️  Invalid monitor config '%s', defaulting to primary\n", t.MonitorsConfig)
			t.MonitorsToCapture = []int{0}
		} else {
			monitors := []string{}
			for _, m := range t.MonitorsToCapture {
				monitors = append(monitors, fmt.Sprintf("%d", m+1))
			}
			fmt.Printf("📸 Will capture: Monitor(s) %s\n", strings.Join(monitors, ", "))
		}
	}
}

// Start capturing
func (t *TaskTracker) StartCapture(taskName string) error {
	t.TaskName = taskName
	if t.TaskName == "" {
		t.TaskName = fmt.Sprintf("Task_%s", t.SessionID)
	}

	t.IsCapturing = true
	t.StartTime = time.Now()

	fmt.Printf("🎬 Started capturing for: %s\n", t.TaskName)
	fmt.Printf("📁 Saving to: %s\n", t.SessionDir)
	fmt.Println("Press Ctrl+C when done\n")

	// Capture loop
	ticker := time.NewTicker(t.CaptureInterval)
	defer ticker.Stop()

	// Initial capture
	t.captureScreenshot()

	for range ticker.C {
		if !t.IsCapturing {
			break
		}
		t.captureScreenshot()
	}

	return nil
}

// Stop capturing
func (t *TaskTracker) StopCapture() error {
	t.IsCapturing = false
	t.EndTime = time.Now()
	duration := t.EndTime.Sub(t.StartTime).Seconds()

	fmt.Printf("\n✅ Capture stopped\n")
	fmt.Printf("⏱️  Duration: %.1f minutes\n", duration/60)
	fmt.Printf("📊 Total screenshots: %d\n", len(t.Screenshots))

	return t.saveMetadata()
}

// Capture screenshot from all configured monitors
func (t *TaskTracker) captureScreenshot() error {
	timestamp := time.Now().Format("150405")

	for _, monitorIdx := range t.MonitorsToCapture {
		img, err := screenshot.CaptureDisplay(monitorIdx)
		if err != nil {
			fmt.Printf("❌ Failed to capture monitor %d: %v\n", monitorIdx+1, err)
			continue
		}

		bounds := img.Bounds()
		resolution := fmt.Sprintf("%dx%d", bounds.Dx(), bounds.Dy())

		// Generate filename
		var filename string
		if len(t.MonitorsToCapture) > 1 {
			filename = fmt.Sprintf("screen_m%d_%s.png", monitorIdx+1, timestamp)
		} else {
			filename = fmt.Sprintf("screen_%s.png", timestamp)
		}

		filepath := filepath.Join(t.SessionDir, filename)

		// Save PNG
		file, err := os.Create(filepath)
		if err != nil {
			return fmt.Errorf("failed to create file: %w", err)
		}

		if err := png.Encode(file, img); err != nil {
			file.Close()
			return fmt.Errorf("failed to encode PNG: %w", err)
		}
		file.Close()

		// Add to screenshots list
		t.Screenshots = append(t.Screenshots, Screenshot{
			Path:         filepath,
			Monitor:      monitorIdx + 1,
			Timestamp:    time.Now().Format(time.RFC3339),
			RelativeTime: time.Since(t.StartTime).Seconds(),
			Resolution:   resolution,
		})
	}

	totalCount := len(t.Screenshots)
	monitorsStr := ""
	if len(t.MonitorsToCapture) > 1 {
		monitors := []string{}
		for _, m := range t.MonitorsToCapture {
			monitors = append(monitors, fmt.Sprintf("%d", m+1))
		}
		monitorsStr = fmt.Sprintf(" (monitors: %s)", strings.Join(monitors, ", "))
	}

	fmt.Printf("📸 Captured: %s%s (%d total screenshots)\n", timestamp, monitorsStr, totalCount)
	return nil
}

// Save session metadata
func (t *TaskTracker) saveMetadata() error {
	metadata := SessionMetadata{
		SessionID:       t.SessionID,
		TaskName:        t.TaskName,
		StartTime:       t.StartTime.Format(time.RFC3339),
		EndTime:         t.EndTime.Format(time.RFC3339),
		DurationSeconds: t.EndTime.Sub(t.StartTime).Seconds(),
		ScreenshotCount: len(t.Screenshots),
		Screenshots:     t.Screenshots,
	}

	data, err := json.MarshalIndent(metadata, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	metadataPath := filepath.Join(t.SessionDir, "metadata.json")
	return os.WriteFile(metadataPath, data, 0644)
}

// Generate review file for Claude Code analysis
func (t *TaskTracker) GenerateReviewFile(sampleCount int) error {
	selected := t.sampleScreenshots(sampleCount)

	duration := t.EndTime.Sub(t.StartTime).Minutes()

	var md strings.Builder
	md.WriteString("# Task Analysis Review\n\n")
	md.WriteString(fmt.Sprintf("**Task Name:** %s\n", t.TaskName))
	md.WriteString(fmt.Sprintf("**Session ID:** %s\n", t.SessionID))
	md.WriteString(fmt.Sprintf("**Duration:** %.1f minutes\n", duration))
	md.WriteString(fmt.Sprintf("**Total Screenshots:** %d\n", len(t.Screenshots)))
	md.WriteString(fmt.Sprintf("**Sampled Screenshots:** %d\n\n", len(selected)))

	md.WriteString("## Screenshots for Analysis\n\n")
	for i, shot := range selected {
		md.WriteString(fmt.Sprintf("### Screenshot %d (%.1f min)\n", i+1, shot.RelativeTime/60))
		md.WriteString(fmt.Sprintf("- **Monitor:** %d\n", shot.Monitor))
		md.WriteString(fmt.Sprintf("- **Resolution:** %s\n", shot.Resolution))
		md.WriteString(fmt.Sprintf("- **Timestamp:** %s\n\n", shot.Timestamp))
		md.WriteString(fmt.Sprintf("![Screenshot](%s)\n\n", shot.Path))
	}

	md.WriteString("\n---\n\n")
	md.WriteString("## Analysis Prompt\n\n")
	md.WriteString("Please analyze the screenshots above and provide:\n\n")
	md.WriteString("1. **What was accomplished**: A clear summary of the work done\n")
	md.WriteString("2. **Key activities**: Main tasks or workflows observed\n")
	md.WriteString("3. **Technologies/Tools used**: What applications or systems were visible\n")
	md.WriteString("4. **Workspace organization**: How different monitors/windows were used (if multi-monitor)\n")
	md.WriteString("5. **Progression**: How the work evolved over time\n")
	md.WriteString("6. **Suggested Jira summary**: A concise 2-3 sentence summary suitable for a Jira task update\n\n")
	md.WriteString("Be specific and focus on the actual work visible in the screenshots.\n")

	reviewPath := filepath.Join(t.SessionDir, "review.md")
	if err := os.WriteFile(reviewPath, []byte(md.String()), 0644); err != nil {
		return fmt.Errorf("failed to save review file: %w", err)
	}

	fmt.Printf("\n✅ Review file generated: %s\n", reviewPath)
	return nil
}

// Sample screenshots evenly
func (t *TaskTracker) sampleScreenshots(count int) []Screenshot {
	if len(t.Screenshots) <= count {
		return t.Screenshots
	}

	selected := []Screenshot{}
	step := float64(len(t.Screenshots)-1) / float64(count-1)

	for i := 0; i < count; i++ {
		idx := int(float64(i) * step)
		selected = append(selected, t.Screenshots[idx])
	}

	return selected
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "task-tracker",
		Short: "AI-powered task tracking with screen capture",
	}

	// Start command
	var startCmd = &cobra.Command{
		Use:   "start [task name]",
		Short: "Start capturing screenshots",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			monitors, _ := cmd.Flags().GetString("monitors")
			interval, _ := cmd.Flags().GetInt("interval")

			tracker, err := NewTaskTracker("task_captures", monitors)
			if err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}

			tracker.CaptureInterval = time.Duration(interval) * time.Second

			taskName := ""
			if len(args) > 0 {
				taskName = args[0]
			}

			// Set up signal handling for graceful shutdown
			sigChan := make(chan os.Signal, 1)
			signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

			// Start capture in a goroutine
			done := make(chan error, 1)
			go func() {
				done <- tracker.StartCapture(taskName)
			}()

			// Wait for either completion or interrupt signal
			select {
			case <-sigChan:
				fmt.Println("\n\n⏸️  Interrupt received, stopping capture...")
				tracker.IsCapturing = false
			case err := <-done:
				if err != nil {
					fmt.Printf("❌ Error during capture: %v\n", err)
					os.Exit(1)
				}
			}

			// Stop capture and save metadata
			if err := tracker.StopCapture(); err != nil {
				fmt.Printf("❌ Error stopping capture: %v\n", err)
				os.Exit(1)
			}

			// Generate review file
			fmt.Println("\n" + strings.Repeat("=", 50))
			fmt.Println("Generating review file for Claude Code analysis...")

			if err := tracker.GenerateReviewFile(5); err != nil {
				fmt.Printf("⚠️  Failed to generate review file: %v\n", err)
			} else {
				reviewPath := filepath.Join(tracker.SessionDir, "review.md")
				fmt.Println("\n" + strings.Repeat("=", 50))
				fmt.Println("📝 NEXT STEPS:")
				fmt.Println("\nTo analyze your session in Claude Code, run:")
				fmt.Printf("  claude-code \"%s\"\n", reviewPath)
				fmt.Println("\nOr open the file in your editor and paste it into Claude Code.")
				fmt.Println("The review file contains all screenshots and an analysis prompt.")
			}
		},
	}

	startCmd.Flags().StringP("monitors", "m", "all", "Monitors to capture (all, primary, 1, 1,2, etc.)")
	startCmd.Flags().IntP("interval", "i", 30, "Capture interval in seconds")

	// Stop command (for stopping a running session)
	var stopCmd = &cobra.Command{
		Use:   "stop",
		Short: "Stop the current capture session gracefully",
		Long: `Stop command is not needed if using Ctrl+C, which now properly saves metadata.
This command is here for completeness but Ctrl+C is the recommended way to stop.`,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("💡 Tip: You can stop capture by pressing Ctrl+C")
			fmt.Println("   Metadata and summary will be generated automatically")
		},
	}

	// Analyze command
	var analyzeCmd = &cobra.Command{
		Use:   "analyze [session_id]",
		Short: "Generate review file for an existing capture session",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			sessionID := args[0]
			sessionDir := filepath.Join("task_captures", sessionID)

			// Load metadata
			metadataPath := filepath.Join(sessionDir, "metadata.json")
			data, err := os.ReadFile(metadataPath)
			if err != nil {
				fmt.Printf("❌ Failed to load session: %v\n", err)
				os.Exit(1)
			}

			var metadata SessionMetadata
			if err := json.Unmarshal(data, &metadata); err != nil {
				fmt.Printf("❌ Failed to parse metadata: %v\n", err)
				os.Exit(1)
			}

			// Reconstruct tracker
			tracker := &TaskTracker{
				SessionID:   metadata.SessionID,
				SessionDir:  sessionDir,
				TaskName:    metadata.TaskName,
				Screenshots: metadata.Screenshots,
			}

			tracker.StartTime, _ = time.Parse(time.RFC3339, metadata.StartTime)
			tracker.EndTime, _ = time.Parse(time.RFC3339, metadata.EndTime)

			// Generate review file
			fmt.Println("Generating review file for Claude Code analysis...")
			if err := tracker.GenerateReviewFile(5); err != nil {
				fmt.Printf("❌ Failed to generate review file: %v\n", err)
				os.Exit(1)
			}

			reviewPath := filepath.Join(sessionDir, "review.md")
			fmt.Println("\n" + strings.Repeat("=", 50))
			fmt.Println("📝 NEXT STEPS:")
			fmt.Println("\nTo analyze your session in Claude Code, run:")
			fmt.Printf("  claude-code \"%s\"\n", reviewPath)
			fmt.Println("\nOr open the file in your editor and paste it into Claude Code.")
		},
	}

	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(analyzeCmd)
	rootCmd.AddCommand(stopCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
