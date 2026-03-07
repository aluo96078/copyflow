#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

// Callback function defined in Go
extern void hotkeyTriggered(void);

static CFMachPortRef eventTap = NULL;
static CFRunLoopSourceRef runLoopSource = NULL;
static int _doStartHotkeyListener(void);

// CGEvent callback for global key monitoring
static CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo) {
    // Re-enable tap if it gets disabled
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        CGEventTapEnable(eventTap, true);
        return event;
    }

    if (type == kCGEventKeyDown) {
        CGKeyCode keyCode = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        CGEventFlags flags = CGEventGetFlags(event);

        // Check for Ctrl+V (keycode 9 = 'v', control flag set, no cmd/option/shift)
        BOOL ctrlPressed = (flags & kCGEventFlagMaskControl) != 0;
        BOOL cmdPressed = (flags & kCGEventFlagMaskCommand) != 0;
        BOOL optPressed = (flags & kCGEventFlagMaskAlternate) != 0;
        BOOL shiftPressed = (flags & kCGEventFlagMaskShift) != 0;

        if (keyCode == 9 && ctrlPressed && !cmdPressed && !optPressed && !shiftPressed) {
            NSLog(@"[ClipFlow] Ctrl+V detected!");
            // Dispatch to main queue for UI safety
            dispatch_async(dispatch_get_main_queue(), ^{
                hotkeyTriggered();
            });
            return NULL;
        }
    }

    return event;
}

// Start listening for global hotkey. Safe to call from any thread.
int startHotkeyListener(void) {
    __block int result = 0;

    // Must set up event tap on main thread
    if ([NSThread isMainThread]) {
        result = _doStartHotkeyListener();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            result = _doStartHotkeyListener();
        });
    }

    return result;
}

static int _doStartHotkeyListener(void) {
    NSLog(@"[ClipFlow] Setting up event tap...");

    CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);

    eventTap = CGEventTapCreate(
        kCGSessionEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,
        mask,
        eventCallback,
        NULL
    );

    if (eventTap == NULL) {
        NSLog(@"[ClipFlow] CGEventTapCreate failed - no accessibility permission");
        return -1;
    }

    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);

    NSLog(@"[ClipFlow] Event tap created successfully - Ctrl+V hotkey active");
    return 0;
}

// Stop listening
void stopHotkeyListener(void) {
    if (eventTap != NULL) {
        CGEventTapEnable(eventTap, false);
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
        CFRelease(runLoopSource);
        CFRelease(eventTap);
        runLoopSource = NULL;
        eventTap = NULL;
    }
}

// Check if accessibility permission is granted (with system prompt)
int checkAccessibilityPermission(void) {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
    BOOL trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    NSLog(@"[ClipFlow] Accessibility check (with prompt): %@", trusted ? @"GRANTED" : @"DENIED");
    return trusted ? 1 : 0;
}

// Check if accessibility permission is granted (silent, no prompt)
int checkAccessibilityPermissionQuiet(void) {
    NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @NO};
    BOOL trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    NSLog(@"[ClipFlow] Accessibility check (quiet): %@", trusted ? @"GRANTED" : @"DENIED");
    return trusted ? 1 : 0;
}
