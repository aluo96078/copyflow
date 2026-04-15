#import <Cocoa/Cocoa.h>
#include <string.h>
#include <stdlib.h>

// Run a block synchronously on the main thread. Safe to call from main too.
static void runOnMain(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

// Get current pasteboard change count
int getPasteboardChangeCount(void) {
    __block int count = 0;
    runOnMain(^{
        count = (int)[[NSPasteboard generalPasteboard] changeCount];
    });
    return count;
}

// Get text content from pasteboard. Caller must free the returned string.
const char* getPasteboardText(void) {
    __block const char *result = NULL;
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        NSString *text = [pb stringForType:NSPasteboardTypeString];
        if (text == nil) return;
        const char *utf8 = [text UTF8String];
        if (utf8 == NULL) return;
        result = strdup(utf8);
    });
    return result;
}

// Get image data from pasteboard (PNG format).
// Returns a malloc'd buffer; caller must free. Sets *outLen to the data length.
const void* getPasteboardImage(int *outLen) {
    __block void *result = NULL;
    __block int len = 0;
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];

        // Try PNG first, then TIFF
        NSData *data = [pb dataForType:NSPasteboardTypePNG];
        if (data == nil) {
            data = [pb dataForType:NSPasteboardTypeTIFF];
            if (data != nil) {
                NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:data];
                if (rep == nil) {
                    return;
                }
                data = [rep representationUsingType:NSBitmapImageFileTypePNG
                                         properties:@{}];
            }
        }

        if (data == nil) return;

        len = (int)[data length];
        if (len <= 0) return;
        void *buf = malloc(len);
        if (buf == NULL) return;
        memcpy(buf, [data bytes], len);
        result = buf;
    });
    *outLen = len;
    return result;
}

// Check if pasteboard contains image data
int pasteboardHasImage(void) {
    __block int has = 0;
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        if ([pb dataForType:NSPasteboardTypePNG] != nil) { has = 1; return; }
        if ([pb dataForType:NSPasteboardTypeTIFF] != nil) { has = 1; return; }
    });
    return has;
}

// Check if pasteboard contains text
int pasteboardHasText(void) {
    __block int has = 0;
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        if ([pb stringForType:NSPasteboardTypeString] != nil) has = 1;
    });
    return has;
}

// Set text to pasteboard. `text` is copied into an NSString before dispatch,
// so the caller's C buffer can be freed immediately after this returns.
void setPasteboardText(const char *text) {
    if (text == NULL) return;
    NSString *str = [NSString stringWithUTF8String:text];
    if (str == nil) return;
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setString:str forType:NSPasteboardTypeString];
    });
}

// Set image (PNG data) to pasteboard. The bytes are copied into an NSData
// before dispatch, so the caller's buffer is safe to free after return.
void setPasteboardImage(const void *data, int len) {
    if (data == NULL || len <= 0) return;
    NSData *imgData = [NSData dataWithBytes:data length:len];
    runOnMain(^{
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
        [pb setData:imgData forType:NSPasteboardTypePNG];
    });
}

// Free a C string or buffer allocated by this module
void freeCString(void *ptr) {
    free(ptr);
}
