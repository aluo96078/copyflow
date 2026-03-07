package clipboard

import (
	"bytes"
	"fmt"
	"image"
	_ "image/png"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type ScreenshotMonitor struct {
	storage  *Storage
	dir      string
	stopCh   chan struct{}
	paused   bool
	known    map[string]bool
}

func NewScreenshotMonitor(storage *Storage) *ScreenshotMonitor {
	dir := getScreenshotDir()
	log.Printf("[ClipFlow] Screenshot monitor watching: %s", dir)
	return &ScreenshotMonitor{
		storage: storage,
		dir:     dir,
		stopCh:  make(chan struct{}),
		known:   make(map[string]bool),
	}
}

func getScreenshotDir() string {
	// Try reading custom screenshot location
	out, err := exec.Command("defaults", "read", "com.apple.screencapture", "location").Output()
	if err == nil {
		dir := strings.TrimSpace(string(out))
		if dir != "" {
			return dir
		}
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, "Desktop")
}

func (sm *ScreenshotMonitor) Start() {
	// Index existing screenshots so we don't import old ones
	sm.indexExisting()
	go sm.poll()
}

func (sm *ScreenshotMonitor) Stop() {
	close(sm.stopCh)
}

func (sm *ScreenshotMonitor) SetPaused(paused bool) {
	sm.paused = paused
}

func (sm *ScreenshotMonitor) SetDir(dir string) {
	sm.dir = dir
}

func (sm *ScreenshotMonitor) indexExisting() {
	entries, err := os.ReadDir(sm.dir)
	if err != nil {
		return
	}
	for _, e := range entries {
		if isScreenshotFile(e.Name()) {
			sm.known[e.Name()] = true
		}
	}
}

func (sm *ScreenshotMonitor) poll() {
	ticker := time.NewTicker(300 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-sm.stopCh:
			return
		case <-ticker.C:
			if sm.paused {
				continue
			}
			sm.check()
		}
	}
}

func (sm *ScreenshotMonitor) check() {
	entries, err := os.ReadDir(sm.dir)
	if err != nil {
		return
	}

	for _, e := range entries {
		name := e.Name()
		if !isScreenshotFile(name) {
			continue
		}
		if sm.known[name] {
			continue
		}
		sm.known[name] = true
		log.Printf("[ClipFlow] New screenshot detected: %s", name)

		fullPath := filepath.Join(sm.dir, name)

		// Wait for file to finish writing (check size stability)
		if !waitForFileReady(fullPath, 3*time.Second) {
			log.Printf("[ClipFlow] Screenshot file not ready: %s", name)
			continue
		}

		data, err := os.ReadFile(fullPath)
		if err != nil || len(data) == 0 {
			log.Printf("[ClipFlow] Failed to read screenshot: %v", err)
			continue
		}

		preview := screenshotPreview(data, name)
		log.Printf("[ClipFlow] Screenshot stored: %s (%d bytes)", preview, len(data))

		sm.storage.Add(ClipboardItem{
			Type:      TypeImage,
			ImageData: data,
			Preview:   preview,
		})

		// Write to system clipboard so user can Cmd+V immediately
		SetImage(data)

		// Delete the file from disk
		os.Remove(fullPath)
	}
}

// waitForFileReady polls file size until it stabilizes (2 consecutive reads match)
func waitForFileReady(path string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	var lastSize int64 = -1
	for time.Now().Before(deadline) {
		info, err := os.Stat(path)
		if err != nil {
			time.Sleep(50 * time.Millisecond)
			continue
		}
		size := info.Size()
		if size > 0 && size == lastSize {
			return true
		}
		lastSize = size
		time.Sleep(80 * time.Millisecond)
	}
	return false
}

func isScreenshotFile(name string) bool {
	lower := strings.ToLower(name)
	// macOS screenshot naming: "Screenshot YYYY-MM-DD at HH.MM.SS" or
	// "螢幕截圖 YYYY-MM-DD ..." (Chinese locale)
	// Also "截圖" for some locales
	isScreenshot := strings.Contains(lower, "screenshot") ||
		strings.Contains(name, "螢幕截圖") ||
		strings.Contains(name, "截圖") ||
		strings.Contains(lower, "截屏")

	isPng := strings.HasSuffix(lower, ".png")

	return isScreenshot && isPng
}

func screenshotPreview(data []byte, filename string) string {
	cfg, _, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return fmt.Sprintf("截圖 · %d KB", len(data)/1024)
	}
	return fmt.Sprintf("截圖 %dx%d · %d KB", cfg.Width, cfg.Height, len(data)/1024)
}
