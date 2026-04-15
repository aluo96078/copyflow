package clipboard

import (
	"bytes"
	"fmt"
	"image"
	_ "image/png"
	"log"
	"sync/atomic"
	"time"
)

type Monitor struct {
	storage   *Storage
	interval  time.Duration
	lastCount int
	paused    atomic.Bool
	stopCh    chan struct{}
}

func (m *Monitor) IsPaused() bool {
	return m.paused.Load()
}

func NewMonitor(storage *Storage, interval time.Duration) *Monitor {
	return &Monitor{
		storage:  storage,
		interval: interval,
		stopCh:   make(chan struct{}),
	}
}

func (m *Monitor) Start() {
	m.lastCount = GetChangeCount()
	go m.poll()
}

func (m *Monitor) Stop() {
	close(m.stopCh)
}

func (m *Monitor) SetPaused(paused bool) {
	m.paused.Store(paused)
}

func (m *Monitor) poll() {
	ticker := time.NewTicker(m.interval)
	defer ticker.Stop()

	for {
		select {
		case <-m.stopCh:
			return
		case <-ticker.C:
			if m.paused.Load() {
				continue
			}
			m.check()
		}
	}
}

func (m *Monitor) check() {
	count := GetChangeCount()
	if count == m.lastCount {
		return
	}
	m.lastCount = count

	hasText := HasText()
	hasImage := HasImage()
	log.Printf("[ClipFlow] Clipboard changed (count=%d) hasText=%v hasImage=%v", count, hasText, hasImage)

	// If both text and image exist, prefer text (most copies from apps include both)
	// Only treat as image if there's NO text (pure image copy / screenshot)
	if hasText {
		text, ok := GetText()
		if ok && len(text) > 0 {
			preview := text
			if len(preview) > 100 {
				preview = preview[:100] + "..."
			}
			log.Printf("[ClipFlow] Stored text: %s", preview)
			m.storage.Add(ClipboardItem{
				Type:     TypeText,
				TextData: text,
				Preview:  preview,
			})
			return
		}
	}

	if hasImage {
		imgData, ok := GetImage()
		if ok && len(imgData) > 0 {
			preview := imageSizePreview(imgData)
			log.Printf("[ClipFlow] Stored image: %s", preview)
			m.storage.Add(ClipboardItem{
				Type:      TypeImage,
				ImageData: imgData,
				Preview:   preview,
			})
		}
	}
}

func imageSizePreview(data []byte) string {
	cfg, _, err := image.DecodeConfig(bytes.NewReader(data))
	if err != nil {
		return fmt.Sprintf("%d KB", len(data)/1024)
	}
	return fmt.Sprintf("%dx%d · %d KB", cfg.Width, cfg.Height, len(data)/1024)
}
