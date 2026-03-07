package hotkey

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa -framework Carbon
#include <stdlib.h>

extern int startHotkeyListener(void);
extern void stopHotkeyListener(void);
extern int checkAccessibilityPermission(void);
extern int checkAccessibilityPermissionQuiet(void);
*/
import "C"

var callback func()

//export hotkeyTriggered
func hotkeyTriggered() {
	if callback != nil {
		callback()
	}
}

func Start(onTrigger func()) error {
	callback = onTrigger
	result := C.startHotkeyListener()
	if result != 0 {
		return ErrNoAccessibility
	}
	return nil
}

func Stop() {
	C.stopHotkeyListener()
}

func CheckAccessibility() bool {
	return C.checkAccessibilityPermission() == 1
}

func CheckAccessibilityQuiet() bool {
	return C.checkAccessibilityPermissionQuiet() == 1
}

type hotkeyError string

func (e hotkeyError) Error() string { return string(e) }

const ErrNoAccessibility = hotkeyError("需要輔助使用權限（Accessibility Permission）才能監聽全域快捷鍵")
