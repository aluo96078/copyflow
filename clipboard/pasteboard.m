#import <Cocoa/Cocoa.h>
#include <string.h>
#include <stdlib.h>

// Get current pasteboard change count
int getPasteboardChangeCount(void) {
    return (int)[[NSPasteboard generalPasteboard] changeCount];
}

// Get text content from pasteboard. Caller must free the returned string.
const char* getPasteboardText(void) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *text = [pb stringForType:NSPasteboardTypeString];
    if (text == nil) return NULL;
    const char *utf8 = [text UTF8String];
    return strdup(utf8);
}

// Get image data from pasteboard (PNG format).
// Returns a malloc'd buffer; caller must free. Sets *outLen to the data length.
const void* getPasteboardImage(int *outLen) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];

    // Try PNG first, then TIFF
    NSData *data = [pb dataForType:NSPasteboardTypePNG];
    if (data == nil) {
        data = [pb dataForType:NSPasteboardTypeTIFF];
        if (data != nil) {
            // Convert TIFF to PNG
            NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:data];
            if (rep == nil) {
                *outLen = 0;
                return NULL;
            }
            data = [rep representationUsingType:NSBitmapImageFileTypePNG
                                     properties:@{}];
        }
    }

    if (data == nil) {
        *outLen = 0;
        return NULL;
    }

    *outLen = (int)[data length];
    void *buf = malloc(*outLen);
    memcpy(buf, [data bytes], *outLen);
    return buf;
}

// Check if pasteboard contains image data
int pasteboardHasImage(void) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    if ([pb dataForType:NSPasteboardTypePNG] != nil) return 1;
    if ([pb dataForType:NSPasteboardTypeTIFF] != nil) return 1;
    return 0;
}

// Check if pasteboard contains text
int pasteboardHasText(void) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    if ([pb stringForType:NSPasteboardTypeString] != nil) return 1;
    return 0;
}

// Set text to pasteboard
void setPasteboardText(const char *text) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    [pb setString:[NSString stringWithUTF8String:text] forType:NSPasteboardTypeString];
}

// Set image (PNG data) to pasteboard
void setPasteboardImage(const void *data, int len) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb clearContents];
    NSData *imgData = [NSData dataWithBytes:data length:len];
    [pb setData:imgData forType:NSPasteboardTypePNG];
}

// Free a C string or buffer allocated by this module
void freeCString(void *ptr) {
    free(ptr);
}
