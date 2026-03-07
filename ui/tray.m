#import <Cocoa/Cocoa.h>

// Callbacks from Go
extern void onTrayQuit(void);
extern void onTrayClearHistory(void);
extern void onTrayTogglePause(void);

static NSStatusItem *statusItem = nil;
static NSMenuItem *pauseItem = nil;
static BOOL isPaused = NO;

@interface TrayDelegate : NSObject
- (void)quit:(id)sender;
- (void)clearHistory:(id)sender;
- (void)togglePause:(id)sender;
@end

@implementation TrayDelegate

- (void)quit:(id)sender {
    onTrayQuit();
}

- (void)clearHistory:(id)sender {
    onTrayClearHistory();
}

- (void)togglePause:(id)sender {
    isPaused = !isPaused;
    if (isPaused) {
        pauseItem.title = @"繼續監控";
        statusItem.button.image = [NSImage imageWithSystemSymbolName:@"clipboard.fill"
                                   accessibilityDescription:@"clipboard paused"];
    } else {
        pauseItem.title = @"暫停監控";
        statusItem.button.image = [NSImage imageWithSystemSymbolName:@"clipboard"
                                   accessibilityDescription:@"clipboard"];
    }
    onTrayTogglePause();
}

@end

static TrayDelegate *trayDelegate = nil;

void initTray(void) {
    trayDelegate = [[TrayDelegate alloc] init];

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.button.image = [NSImage imageWithSystemSymbolName:@"clipboard"
                               accessibilityDescription:@"clipboard"];

    NSMenu *menu = [[NSMenu alloc] init];

    NSMenuItem *titleItem = [[NSMenuItem alloc] initWithTitle:@"Clipboard Manager" action:nil keyEquivalent:@""];
    titleItem.enabled = NO;
    [menu addItem:titleItem];

    [menu addItem:[NSMenuItem separatorItem]];

    pauseItem = [[NSMenuItem alloc] initWithTitle:@"暫停監控" action:@selector(togglePause:) keyEquivalent:@""];
    pauseItem.target = trayDelegate;
    [menu addItem:pauseItem];

    NSMenuItem *clearItem = [[NSMenuItem alloc] initWithTitle:@"清除歷程" action:@selector(clearHistory:) keyEquivalent:@""];
    clearItem.target = trayDelegate;
    [menu addItem:clearItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *hotkeyInfoItem = [[NSMenuItem alloc] initWithTitle:@"快捷鍵：Ctrl+V" action:nil keyEquivalent:@""];
    hotkeyInfoItem.enabled = NO;
    [menu addItem:hotkeyInfoItem];

    [menu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"結束" action:@selector(quit:) keyEquivalent:@"q"];
    quitItem.target = trayDelegate;
    [menu addItem:quitItem];

    statusItem.menu = menu;
}
