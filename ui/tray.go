package ui

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa

extern void initTray(void);
*/
import "C"

var (
	onQuit         func()
	onClearHistory func()
	onTogglePause  func()
)

//export onTrayQuit
func onTrayQuit() {
	if onQuit != nil {
		onQuit()
	}
}

//export onTrayClearHistory
func onTrayClearHistory() {
	if onClearHistory != nil {
		onClearHistory()
	}
}

//export onTrayTogglePause
func onTrayTogglePause() {
	if onTogglePause != nil {
		onTogglePause()
	}
}

type TrayCallbacks struct {
	OnQuit         func()
	OnClearHistory func()
	OnTogglePause  func()
}

func InitTray(cb TrayCallbacks) {
	onQuit = cb.OnQuit
	onClearHistory = cb.OnClearHistory
	onTogglePause = cb.OnTogglePause
	C.initTray()
}
