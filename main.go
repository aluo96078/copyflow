package main

import (
	"clipflow/clipboard"
	"clipflow/hotkey"
	"clipflow/ui"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"time"
)

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa

#include <Cocoa/Cocoa.h>
*/
import "C"

func init() {
	runtime.LockOSThread()
}

func main() {
	storage := clipboard.NewStorage(50)
	monitor := clipboard.NewMonitor(storage, 500*time.Millisecond)
	screenshotMon := clipboard.NewScreenshotMonitor(storage)

	// Initialize UI panel
	ui.Init(func(index int) {
		item, ok := storage.Get(index)
		if !ok {
			return
		}
		switch item.Type {
		case clipboard.TypeText:
			clipboard.SetText(item.TextData)
		case clipboard.TypeImage:
			clipboard.SetImage(item.ImageData)
		}
		ui.Hide()
	})

	// Disable macOS screenshot thumbnail preview for instant file write
	hadThumbnail := disableScreenshotThumbnail()

	// Initialize system tray
	ui.InitTray(ui.TrayCallbacks{
		OnQuit: func() {
			monitor.Stop()
			screenshotMon.Stop()
			hotkey.Stop()
			if hadThumbnail {
				restoreScreenshotThumbnail()
			}
			os.Exit(0)
		},
		OnClearHistory: func() {
			storage.Clear()
		},
		OnTogglePause: func() {
			paused := !monitor.IsPaused()
			monitor.SetPaused(paused)
			screenshotMon.SetPaused(paused)
		},
	})

	// Check accessibility permission, wait if not granted
	hotkeyHandler := func() {
		if ui.IsVisible() {
			ui.Hide()
			return
		}
		items := storage.GetAll()
		ui.Show(items)
	}

	if !hotkey.CheckAccessibility() {
		fmt.Println("請在「系統設定 > 隱私權與安全性 > 輔助使用」中允許本程式")
		fmt.Println("授權後將自動啟用快捷鍵，請稍候...")
		// Open System Settings directly to Accessibility page
		exec.Command("open", "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility").Run()
		go func() {
			for {
				time.Sleep(2 * time.Second)
				if hotkey.CheckAccessibilityQuiet() {
					fmt.Println("已取得輔助使用權限！")
					if err := hotkey.Start(hotkeyHandler); err == nil {
						fmt.Println("快捷鍵 Ctrl+V 已啟用")
					}
					return
				}
			}
		}()
	} else {
		err := hotkey.Start(hotkeyHandler)
		if err != nil {
			fmt.Fprintf(os.Stderr, "快捷鍵監聽啟動失敗：%v\n", err)
			os.Exit(1)
		}
	}

	// Start clipboard monitor & screenshot monitor
	monitor.Start()
	screenshotMon.Start()

	fmt.Println("ClipFlow 已啟動")
	fmt.Println("快捷鍵：Ctrl+V 開啟剪貼簿歷程")
	fmt.Println("系統列圖示可暫停、清除歷程或結束程式")

	// Run the macOS main event loop
	C.NSApplicationMain(0, nil)
}

// disableScreenshotThumbnail disables the macOS screenshot floating thumbnail preview.
// Returns true if the thumbnail was previously enabled (so we can restore it on quit).
func disableScreenshotThumbnail() bool {
	out, err := exec.Command("defaults", "read", "com.apple.screencapture", "show-thumbnail").Output()
	wasEnabled := err != nil || string(out) != "0\n" // default is enabled
	exec.Command("defaults", "write", "com.apple.screencapture", "show-thumbnail", "-bool", "false").Run()
	return wasEnabled
}

func restoreScreenshotThumbnail() {
	exec.Command("defaults", "write", "com.apple.screencapture", "show-thumbnail", "-bool", "true").Run()
}
