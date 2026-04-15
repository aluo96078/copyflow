package ui

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>

extern void initPanel(void);
extern void clearPanelItems(void);
extern void addTextItem(int index, const char *preview, const char *timeStr);
extern void addImageItem(int index, const void *pngData, int dataLen, const char *sizeStr, const char *timeStr);
extern void showPanel(void);
extern void hidePanel(void);
extern int isPanelVisible(void);
*/
import "C"
import (
	"clipflow/clipboard"
	"fmt"
	"time"
	"unsafe"
)

var onSelect func(index int)

//export onItemSelected
func onItemSelected(index C.int) {
	if onSelect != nil {
		onSelect(int(index))
	}
}

func Init(selectCallback func(index int)) {
	onSelect = selectCallback
	C.initPanel()
}

func Show(items []clipboard.ClipboardItem) {
	C.clearPanelItems()

	for i, item := range items {
		timeStr := formatTime(item.CopiedAt)
		cTime := C.CString(timeStr)

		switch item.Type {
		case clipboard.TypeText:
			cPreview := C.CString(item.Preview)
			C.addTextItem(C.int(i), cPreview, cTime)
			C.free(unsafe.Pointer(cPreview))

		case clipboard.TypeImage:
			if len(item.ImageData) == 0 {
				C.free(unsafe.Pointer(cTime))
				continue
			}
			cSize := C.CString(item.Preview)
			cData := C.CBytes(item.ImageData)
			C.addImageItem(
				C.int(i),
				cData,
				C.int(len(item.ImageData)),
				cSize,
				cTime,
			)
			C.free(cData)
			C.free(unsafe.Pointer(cSize))
		}

		C.free(unsafe.Pointer(cTime))
	}

	C.showPanel()
}

func Hide() {
	C.hidePanel()
}

func IsVisible() bool {
	return C.isPanelVisible() == 1
}

func formatTime(t time.Time) string {
	now := time.Now()
	diff := now.Sub(t)

	switch {
	case diff < time.Minute:
		return "剛剛"
	case diff < time.Hour:
		return fmt.Sprintf("%d 分鐘前", int(diff.Minutes()))
	case diff < 24*time.Hour:
		return fmt.Sprintf("%d 小時前", int(diff.Hours()))
	default:
		return t.Format("01/02 15:04")
	}
}
