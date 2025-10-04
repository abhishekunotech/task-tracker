// Monitor Helper - Detect and configure monitors
// Build: go build -o monitor-helper monitor-helper.go

package main

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"os"
	"time"

	"github.com/kbinani/screenshot"
	"github.com/spf13/cobra"
	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
)

// MonitorPreset stores saved monitor configurations
type MonitorPreset struct {
	Monitors    string `json:"monitors"`
	Description string `json:"description"`
	Created     string `json:"created"`
}

// Detect and display all monitors
func detectMonitors() {
	n := screenshot.NumActiveDisplays()
	fmt.Printf("\n🖥️  Detected %d monitor(s):\n\n", n)
	fmt.Printf("%-5s %-15s %-20s %-15s\n", "#", "Resolution", "Position", "Size (approx)")
	fmt.Println("---------------------------------------------------------------")

	for i := 0; i < n; i++ {
		bounds := screenshot.GetDisplayBounds(i)
		width := bounds.Dx()
		height := bounds.Dy()

		// Estimate physical size (assuming 96 DPI)
		widthInches := float64(width) / 96.0
		heightInches := float64(height) / 96.0
		diagonal := (widthInches*widthInches + heightInches*heightInches)

		fmt.Printf("%-5d %dx%-10d (%d, %d)%-10s ~%.1f\"\n",
			i+1, width, height, bounds.Min.X, bounds.Min.Y, "",
			(widthInches*widthInches + heightInches*heightInches))
		fmt.Printf("Diagonal width is : %v \n", diagonal)
	}

	fmt.Println("\n💡 Tips:")
	fmt.Println("   - Monitor #1 is typically your primary monitor")
	fmt.Println("   - Position shows where the monitor is in your layout")
	fmt.Println("   - Use 'monitor-helper test-all' to identify each monitor visually")
}

// Add text to image
func addLabel(img *image.RGBA, text string) {
	col := color.RGBA{255, 255, 255, 255}
	point := fixed.Point26_6{X: fixed.I(20), Y: fixed.I(40)}

	// Draw background
	bgColor := color.RGBA{0, 0, 0, 200}
	bgRect := image.Rect(10, 10, 600, 80)
	draw.Draw(img, bgRect, &image.Uniform{bgColor}, image.Point{}, draw.Over)

	// Draw text
	d := &font.Drawer{
		Dst:  img,
		Src:  image.NewUniform(col),
		Face: basicfont.Face7x13,
		Dot:  point,
	}
	d.DrawString(text)
}

// Capture test screenshot from a specific monitor
func testCapture(monitorNum int) error {
	n := screenshot.NumActiveDisplays()

	if monitorNum < 1 || monitorNum > n {
		return fmt.Errorf("invalid monitor number %d. Available: 1-%d", monitorNum, n)
	}

	idx := monitorNum - 1
	fmt.Printf("\n📸 Capturing test screenshot from Monitor %d...\n", monitorNum)

	img, err := screenshot.CaptureDisplay(idx)
	if err != nil {
		return fmt.Errorf("failed to capture: %w", err)
	}

	bounds := img.Bounds()
	rgba := image.NewRGBA(bounds)
	draw.Draw(rgba, bounds, img, bounds.Min, draw.Src)

	// Add label
	text := fmt.Sprintf("Monitor %d Test - %dx%d", monitorNum, bounds.Dx(), bounds.Dy())
	addLabel(rgba, text)

	// Save
	filename := fmt.Sprintf("test_monitor_%d.png", monitorNum)
	file, err := os.Create(filename)
	if err != nil {
		return fmt.Errorf("failed to create file: %w", err)
	}
	defer file.Close()

	if err := png.Encode(file, rgba); err != nil {
		return fmt.Errorf("failed to encode PNG: %w", err)
	}

	fmt.Printf("✅ Saved to: %s\n", filename)
	fmt.Println("   Open this file to verify you're capturing the correct monitor")

	return nil
}

// Test all monitors
func testAllMonitors() error {
	n := screenshot.NumActiveDisplays()
	fmt.Printf("\n📸 Capturing test screenshots from all %d monitors...\n\n", n)

	for i := 1; i <= n; i++ {
		if err := testCapture(i); err != nil {
			fmt.Printf("⚠️  Failed to capture monitor %d: %v\n", i, err)
			continue
		}
		time.Sleep(500 * time.Millisecond)
	}

	fmt.Printf("\n✅ Created %d test screenshots\n", n)
	fmt.Println("   Review them to identify which monitor is which")

	return nil
}

// Save a preset
func savePreset(name, monitors, description string) error {
	presetsFile := "monitor_presets.json"

	// Load existing presets
	presets := make(map[string]MonitorPreset)
	if data, err := os.ReadFile(presetsFile); err == nil {
		json.Unmarshal(data, &presets)
	}

	// Add new preset
	presets[name] = MonitorPreset{
		Monitors:    monitors,
		Description: description,
		Created:     time.Now().Format("2006-01-02 15:04:05"),
	}

	// Save
	data, err := json.MarshalIndent(presets, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal presets: %w", err)
	}

	if err := os.WriteFile(presetsFile, data, 0644); err != nil {
		return fmt.Errorf("failed to save presets: %w", err)
	}

	fmt.Printf("✅ Saved preset '%s': monitors=%s\n", name, monitors)
	if description != "" {
		fmt.Printf("   Description: %s\n", description)
	}

	return nil
}

// List all presets
func listPresets() error {
	presetsFile := "monitor_presets.json"

	data, err := os.ReadFile(presetsFile)
	if err != nil {
		fmt.Println("\n📋 No presets saved yet")
		fmt.Println("\nCreate a preset with:")
		fmt.Println("  monitor-helper preset <name> <monitors> [description]")
		return nil
	}

	var presets map[string]MonitorPreset
	if err := json.Unmarshal(data, &presets); err != nil {
		return fmt.Errorf("failed to parse presets: %w", err)
	}

	if len(presets) == 0 {
		fmt.Println("\n📋 No presets saved yet")
		return nil
	}

	fmt.Println("\n📋 Saved Monitor Presets:")
	for name, preset := range presets {
		fmt.Printf("  • %s\n", name)
		fmt.Printf("    Monitors: %s\n", preset.Monitors)
		if preset.Description != "" {
			fmt.Printf("    Description: %s\n", preset.Description)
		}
		fmt.Printf("    Created: %s\n\n", preset.Created)
	}

	fmt.Println("💡 Use a preset with:")
	fmt.Println("  task-tracker start 'Task name' --monitors <monitors>")

	return nil
}

// Get preset monitors config
func getPreset(name string) {
	presetsFile := "monitor_presets.json"

	data, err := os.ReadFile(presetsFile)
	if err != nil {
		fmt.Println("all") // Default fallback
		return
	}

	var presets map[string]MonitorPreset
	if err := json.Unmarshal(data, &presets); err != nil {
		fmt.Println("all")
		return
	}

	if preset, ok := presets[name]; ok {
		fmt.Println(preset.Monitors)
	} else {
		fmt.Println("all")
	}
}

// Interactive setup wizard
func interactiveSetup() error {
	fmt.Println("\n" + "================================================================")
	fmt.Println("  🎯 Task Tracker - Monitor Setup Wizard")
	fmt.Println("================================================================")

	// Step 1: Detect monitors
	detectMonitors()

	n := screenshot.NumActiveDisplays()
	if n == 1 {
		fmt.Println("\n✅ You have 1 monitor. No configuration needed!")
		fmt.Println("   Just use: task-tracker start 'Task name'")
		return nil
	}

	// Step 2: Test captures
	fmt.Println("\n" + "----------------------------------------------------------------")
	fmt.Println("Step 1: Let's test each monitor to identify them")
	fmt.Println("----------------------------------------------------------------")

	fmt.Print("\nPress Enter to capture test screenshots from all monitors...")
	fmt.Scanln()

	if err := testAllMonitors(); err != nil {
		return err
	}

	fmt.Println("\n✅ Please review the test_monitor_*.png files to identify each monitor")
	fmt.Print("\nPress Enter when ready to continue...")
	fmt.Scanln()

	// Step 3: Create presets
	fmt.Println("\n" + "----------------------------------------------------------------")
	fmt.Println("Step 2: Let's create some useful presets")
	fmt.Println("----------------------------------------------------------------")

	fmt.Println("\n💡 Common multi-monitor workflows:")
	fmt.Println("   • Coding: Code editor + browser/docs")
	fmt.Println("   • Design: Design tool + references")
	fmt.Println("   • Meeting: Video call + notes")
	fmt.Println("   • Testing: Code + browser + terminal")

	for {
		fmt.Println("\n" + "----------------------------------------------------------------")
		fmt.Print("\nWould you like to create a preset? (y/n): ")

		var create string
		fmt.Scanln(&create)

		if create != "y" && create != "Y" {
			break
		}

		fmt.Print("Preset name (e.g., 'coding', 'design', 'meeting'): ")
		var name string
		fmt.Scanln(&name)

		if name == "" {
			fmt.Println("❌ Preset name cannot be empty")
			continue
		}

		fmt.Println("\nWhich monitors for '" + name + "'?")
		fmt.Println("  Examples: all, primary, 1, 1,2, 2,3")
		fmt.Print("Monitors: ")
		var monitors string
		fmt.Scanln(&monitors)
		if monitors == "" {
			monitors = "all"
		}

		fmt.Print("Description (optional): ")
		var description string
		fmt.Scanln(&description)

		if err := savePreset(name, monitors, description); err != nil {
			fmt.Printf("❌ Failed to save preset: %v\n", err)
		}
	}

	// Step 4: Summary
	fmt.Println("\n" + "================================================================")
	fmt.Println("  ✅ Setup Complete!")
	fmt.Println("================================================================")

	listPresets()

	fmt.Println("\n🎉 You're all set! Try it out:")
	fmt.Println("  task-tracker start 'My task' --monitors all")

	// Show preset example if any exist
	presetsFile := "monitor_presets.json"
	if data, err := os.ReadFile(presetsFile); err == nil {
		var presets map[string]MonitorPreset
		if json.Unmarshal(data, &presets) == nil && len(presets) > 0 {
			for name, preset := range presets {
				fmt.Printf("  task-tracker start 'My task' --monitors %s  # Using '%s' preset\n",
					preset.Monitors, name)
				break
			}
		}
	}

	return nil
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "monitor-helper",
		Short: "Multi-monitor configuration tool for task-tracker",
		Long:  "Detect monitors, create test screenshots, and manage monitor presets",
	}

	// Detect command
	var detectCmd = &cobra.Command{
		Use:   "detect",
		Short: "Detect and show all monitors",
		Run: func(cmd *cobra.Command, args []string) {
			detectMonitors()
		},
	}

	// Test command
	var testCmd = &cobra.Command{
		Use:   "test [monitor_num]",
		Short: "Capture test screenshot from monitor",
		Args:  cobra.MaximumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				fmt.Println("Usage: monitor-helper test <monitor_num>")
				fmt.Println("   or: monitor-helper test-all")
				return
			}

			monitorNum := 0
			fmt.Sscanf(args[0], "%d", &monitorNum)

			if err := testCapture(monitorNum); err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	// Test-all command
	var testAllCmd = &cobra.Command{
		Use:   "test-all",
		Short: "Capture test screenshots from all monitors",
		Run: func(cmd *cobra.Command, args []string) {
			if err := testAllMonitors(); err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	// Preset command
	var presetCmd = &cobra.Command{
		Use:   "preset <name> <monitors> [description]",
		Short: "Save a monitor configuration preset",
		Args:  cobra.RangeArgs(2, 3),
		Run: func(cmd *cobra.Command, args []string) {
			name := args[0]
			monitors := args[1]
			description := ""
			if len(args) > 2 {
				description = args[2]
			}

			if err := savePreset(name, monitors, description); err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	// List command
	var listCmd = &cobra.Command{
		Use:   "list",
		Short: "List all saved presets",
		Run: func(cmd *cobra.Command, args []string) {
			if err := listPresets(); err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	// Get command
	var getCmd = &cobra.Command{
		Use:   "get <preset_name>",
		Short: "Get monitors config from preset",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			getPreset(args[0])
		},
	}

	// Setup command
	var setupCmd = &cobra.Command{
		Use:   "setup",
		Short: "Interactive setup wizard",
		Run: func(cmd *cobra.Command, args []string) {
			if err := interactiveSetup(); err != nil {
				fmt.Printf("❌ Error: %v\n", err)
				os.Exit(1)
			}
		},
	}

	rootCmd.AddCommand(detectCmd)
	rootCmd.AddCommand(testCmd)
	rootCmd.AddCommand(testAllCmd)
	rootCmd.AddCommand(presetCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(getCmd)
	rootCmd.AddCommand(setupCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
