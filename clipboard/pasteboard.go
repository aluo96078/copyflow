package clipboard

/*
#cgo CFLAGS: -x objective-c -fobjc-arc
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>

extern int getPasteboardChangeCount(void);
extern const char* getPasteboardText(void);
extern const void* getPasteboardImage(int *outLen);
extern int pasteboardHasImage(void);
extern int pasteboardHasText(void);
extern void setPasteboardText(const char *text);
extern void setPasteboardImage(const void *data, int len);
extern void freeCString(void *ptr);
*/
import "C"
import "unsafe"

func GetChangeCount() int {
	return int(C.getPasteboardChangeCount())
}

func GetText() (string, bool) {
	cstr := C.getPasteboardText()
	if cstr == nil {
		return "", false
	}
	defer C.freeCString(unsafe.Pointer(cstr))
	return C.GoString(cstr), true
}

func GetImage() ([]byte, bool) {
	var length C.int
	ptr := C.getPasteboardImage(&length)
	if ptr == nil || length == 0 {
		return nil, false
	}
	defer C.freeCString(unsafe.Pointer(ptr))
	return C.GoBytes(unsafe.Pointer(ptr), length), true
}

func HasImage() bool {
	return C.pasteboardHasImage() == 1
}

func HasText() bool {
	return C.pasteboardHasText() == 1
}

func SetText(text string) {
	cstr := C.CString(text)
	defer C.free(unsafe.Pointer(cstr))
	C.setPasteboardText(cstr)
}

func SetImage(data []byte) {
	if len(data) == 0 {
		return
	}
	cData := C.CBytes(data)
	defer C.free(cData)
	C.setPasteboardImage(cData, C.int(len(data)))
}
