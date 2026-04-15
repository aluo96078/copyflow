#import <Cocoa/Cocoa.h>

// Callback when user selects an item by index
extern void onItemSelected(int index);

// ─── ClipboardItemView ───────────────────────────────────────────────

@interface ClipboardItemView : NSView
@property (nonatomic, assign) int itemIndex;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *subtitleLabel;
@property (nonatomic, strong) NSImageView *thumbnailView;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL isImageItem;
@end

@implementation ClipboardItemView

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 8;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[NSColor separatorColor] colorWithAlphaComponent:0.3].CGColor;
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.4].CGColor;
        self.layer.masksToBounds = YES;

        _titleLabel = [NSTextField labelWithString:@""];
        _titleLabel.font = [NSFont systemFontOfSize:13];
        _titleLabel.textColor = [NSColor labelColor];
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _titleLabel.maximumNumberOfLines = 2;
        _titleLabel.cell.truncatesLastVisibleLine = YES;
        [_titleLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
        [_titleLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];

        _subtitleLabel = [NSTextField labelWithString:@""];
        _subtitleLabel.font = [NSFont systemFontOfSize:10];
        _subtitleLabel.textColor = [NSColor secondaryLabelColor];
        _subtitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_subtitleLabel setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];

        _thumbnailView = [[NSImageView alloc] init];
        _thumbnailView.imageScaling = NSImageScaleProportionallyUpOrDown;
        _thumbnailView.wantsLayer = YES;
        _thumbnailView.layer.cornerRadius = 4;
        _thumbnailView.layer.masksToBounds = YES;
        _thumbnailView.hidden = YES;

        for (NSView *v in @[_titleLabel, _subtitleLabel, _thumbnailView]) {
            v.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:v];
        }

        // Common constraints (leading/trailing for all labels)
        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-12],
            [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],

            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
            [_subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-12],
            [_subtitleLabel.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-6],
            [_subtitleLabel.topAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.bottomAnchor constant:4],
        ]];
    }
    return self;
}

- (void)configureForImage {
    _thumbnailView.hidden = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_thumbnailView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12],
        [_thumbnailView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12],
        [_thumbnailView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:6],
        [_thumbnailView.bottomAnchor constraintEqualToAnchor:_subtitleLabel.topAnchor constant:-6],
    ]];
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    if (isSelected) {
        self.layer.backgroundColor = [[NSColor controlAccentColor] colorWithAlphaComponent:0.35].CGColor;
        self.layer.borderColor = [[NSColor controlAccentColor] colorWithAlphaComponent:0.6].CGColor;
        self.layer.borderWidth = 2;
    } else {
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.4].CGColor;
        self.layer.borderColor = [[NSColor separatorColor] colorWithAlphaComponent:0.3].CGColor;
        self.layer.borderWidth = 1;
    }
}

- (void)mouseDown:(NSEvent *)event {
    onItemSelected(self.itemIndex);
}

// Hover effect
- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    for (NSTrackingArea *area in self.trackingAreas) {
        [self removeTrackingArea:area];
    }
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc]
        initWithRect:self.bounds
        options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
        owner:self
        userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    if (!_isSelected) {
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.7].CGColor;
    }
}

- (void)mouseExited:(NSEvent *)event {
    if (!_isSelected) {
        self.layer.backgroundColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.4].CGColor;
    }
}

@end

// ─── ClipboardPanel ──────────────────────────────────────────────────

@interface ClipboardPanel : NSPanel
@end

@implementation ClipboardPanel

- (BOOL)canBecomeKeyWindow {
    return YES;
}

- (void)cancelOperation:(id)sender {
    [self orderOut:nil];
}

@end

// ─── ClipboardPanelController ────────────────────────────────────────

@interface ClipboardPanelController : NSObject
@property (nonatomic, strong) ClipboardPanel *panel;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSStackView *stackView;
@property (nonatomic, strong) NSTextField *headerLabel;
@property (nonatomic, strong) NSTextField *emptyLabel;
@property (nonatomic, strong) NSVisualEffectView *effectView;
@property (nonatomic, assign) int selectedIndex;
@property (nonatomic, assign) int itemCount;
@end

@implementation ClipboardPanelController

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedIndex = 0;
        _itemCount = 0;

        NSRect frame = NSMakeRect(0, 0, 360, 480);
        _panel = [[ClipboardPanel alloc]
            initWithContentRect:frame
            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView)
            backing:NSBackingStoreBuffered
            defer:NO];
        _panel.level = NSFloatingWindowLevel;
        _panel.titleVisibility = NSWindowTitleHidden;
        _panel.titlebarAppearsTransparent = YES;
        _panel.movableByWindowBackground = YES;
        _panel.backgroundColor = [NSColor clearColor];
        // Lock the panel size so it never shrinks/grows with contents
        NSSize fixedSize = NSMakeSize(360, 480);
        _panel.minSize = fixedSize;
        _panel.maxSize = fixedSize;
        [_panel setContentSize:fixedSize];

        _effectView = [[NSVisualEffectView alloc] initWithFrame:frame];
        _effectView.material = NSVisualEffectMaterialHUDWindow;
        _effectView.state = NSVisualEffectStateActive;
        _effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        _effectView.wantsLayer = YES;
        _effectView.layer.cornerRadius = 12;
        _effectView.layer.masksToBounds = YES;
        _effectView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [_panel.contentView addSubview:_effectView];

        // Header
        _headerLabel = [NSTextField labelWithString:@"ClipFlow"];
        _headerLabel.font = [NSFont boldSystemFontOfSize:16];
        _headerLabel.textColor = [NSColor labelColor];
        _headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_effectView addSubview:_headerLabel];

        // Shortcut hint
        NSTextField *hintLabel = [NSTextField labelWithString:@"↑↓ 選取  ↵ 貼上  esc 關閉"];
        hintLabel.font = [NSFont systemFontOfSize:10];
        hintLabel.textColor = [NSColor tertiaryLabelColor];
        hintLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_effectView addSubview:hintLabel];

        // Empty state label
        _emptyLabel = [NSTextField labelWithString:@"尚無剪貼簿歷程"];
        _emptyLabel.font = [NSFont systemFontOfSize:13];
        _emptyLabel.textColor = [NSColor secondaryLabelColor];
        _emptyLabel.alignment = NSTextAlignmentCenter;
        _emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _emptyLabel.hidden = YES;
        [_effectView addSubview:_emptyLabel];

        // Stack view
        _stackView = [[NSStackView alloc] init];
        _stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
        _stackView.spacing = 6;
        _stackView.edgeInsets = NSEdgeInsetsMake(4, 0, 4, 0);
        _stackView.translatesAutoresizingMaskIntoConstraints = NO;

        // Scroll view
        _scrollView = [[NSScrollView alloc] init];
        _scrollView.documentView = _stackView;
        _scrollView.hasVerticalScroller = YES;
        _scrollView.automaticallyAdjustsContentInsets = NO;
        _scrollView.contentInsets = NSEdgeInsetsMake(0, 0, 0, 0);
        _scrollView.drawsBackground = NO;
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        [_effectView addSubview:_scrollView];

        [NSLayoutConstraint activateConstraints:@[
            [_headerLabel.topAnchor constraintEqualToAnchor:_effectView.topAnchor constant:36],
            [_headerLabel.leadingAnchor constraintEqualToAnchor:_effectView.leadingAnchor constant:16],

            [hintLabel.centerYAnchor constraintEqualToAnchor:_headerLabel.centerYAnchor],
            [hintLabel.trailingAnchor constraintEqualToAnchor:_effectView.trailingAnchor constant:-16],

            [_scrollView.topAnchor constraintEqualToAnchor:_headerLabel.bottomAnchor constant:12],
            [_scrollView.leadingAnchor constraintEqualToAnchor:_effectView.leadingAnchor constant:8],
            [_scrollView.trailingAnchor constraintEqualToAnchor:_effectView.trailingAnchor constant:-8],
            [_scrollView.bottomAnchor constraintEqualToAnchor:_effectView.bottomAnchor constant:-10],

            [_stackView.leadingAnchor constraintEqualToAnchor:_scrollView.leadingAnchor],
            [_stackView.trailingAnchor constraintEqualToAnchor:_scrollView.trailingAnchor],
            [_stackView.topAnchor constraintEqualToAnchor:_scrollView.topAnchor],
            [_stackView.widthAnchor constraintEqualToAnchor:_scrollView.widthAnchor],

            [_emptyLabel.centerXAnchor constraintEqualToAnchor:_effectView.centerXAnchor],
            [_emptyLabel.centerYAnchor constraintEqualToAnchor:_effectView.centerYAnchor],
        ]];
    }
    return self;
}

- (void)updateSelection {
    NSArray *views = _stackView.arrangedSubviews;
    for (int i = 0; i < (int)views.count; i++) {
        ClipboardItemView *v = (ClipboardItemView *)views[i];
        v.isSelected = (i == _selectedIndex);
    }
    // Scroll selected item into view
    if (_selectedIndex >= 0 && _selectedIndex < (int)views.count) {
        NSView *selectedView = views[_selectedIndex];
        NSRect itemFrame = selectedView.frame;
        NSRect converted = [selectedView.superview convertRect:itemFrame toView:_scrollView.contentView];
        [_scrollView.contentView scrollRectToVisible:converted];
    }
}

- (void)keyDown:(NSEvent *)event {
    switch (event.keyCode) {
        case 125: // Down arrow
            if (_selectedIndex < _itemCount - 1) {
                _selectedIndex++;
                [self updateSelection];
            }
            break;
        case 126: // Up arrow
            if (_selectedIndex > 0) {
                _selectedIndex--;
                [self updateSelection];
            }
            break;
        case 36: // Enter
            if (_itemCount > 0) {
                onItemSelected(_selectedIndex);
            }
            break;
        case 53: // Escape
            [_panel orderOut:nil];
            break;
        default:
            break;
    }
}

@end

// ─── KeyHandlingView ─────────────────────────────────────────────────

@interface KeyHandlingView : NSView
@property (nonatomic, weak) ClipboardPanelController *controller;
@end

@implementation KeyHandlingView

- (BOOL)acceptsFirstResponder { return YES; }

- (void)keyDown:(NSEvent *)event {
    [self.controller keyDown:event];
}

@end

// ─── C Interface ─────────────────────────────────────────────────────

static ClipboardPanelController *panelController = nil;
static KeyHandlingView *keyView = nil;

void initPanel(void) {
    if (panelController == nil) {
        panelController = [[ClipboardPanelController alloc] init];
        keyView = [[KeyHandlingView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        keyView.controller = panelController;
        [panelController.panel.contentView addSubview:keyView];
    }
}

void clearPanelItems(void) {
    if (panelController == nil) return;
    for (NSView *v in [panelController.stackView.arrangedSubviews copy]) {
        [panelController.stackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    panelController.itemCount = 0;
    panelController.selectedIndex = 0;
}

void addTextItem(int index, const char *preview, const char *timeStr) {
    if (panelController == nil) return;
    NSString *text = [NSString stringWithUTF8String:preview];
    NSString *time = [NSString stringWithUTF8String:timeStr];

    ClipboardItemView *item = [[ClipboardItemView alloc] initWithFrame:NSMakeRect(0, 0, 336, 72)];
    item.itemIndex = index;
    item.isImageItem = NO;
    item.titleLabel.stringValue = text;
    item.subtitleLabel.stringValue = [NSString stringWithFormat:@"Aa  %@", time];

    [NSLayoutConstraint activateConstraints:@[
        [item.heightAnchor constraintEqualToConstant:72],
    ]];

    [panelController.stackView addArrangedSubview:item];
    panelController.itemCount++;
}

void addImageItem(int index, const void *pngData, int dataLen, const char *sizeStr, const char *timeStr) {
    if (panelController == nil) return;
    NSData *data = [NSData dataWithBytes:pngData length:dataLen];
    NSImage *img = [[NSImage alloc] initWithData:data];
    NSString *size = [NSString stringWithUTF8String:sizeStr];
    NSString *time = [NSString stringWithUTF8String:timeStr];

    ClipboardItemView *item = [[ClipboardItemView alloc] initWithFrame:NSMakeRect(0, 0, 336, 110)];
    item.itemIndex = index;
    item.isImageItem = YES;
    item.titleLabel.stringValue = [NSString stringWithFormat:@"%@", size];
    item.thumbnailView.image = img;
    [item configureForImage];
    item.subtitleLabel.stringValue = time;

    [NSLayoutConstraint activateConstraints:@[
        [item.heightAnchor constraintEqualToConstant:110],
    ]];

    [panelController.stackView addArrangedSubview:item];
    panelController.itemCount++;
}

void showPanel(void) {
    if (panelController == nil) return;

    panelController.selectedIndex = 0;
    [panelController updateSelection];

    panelController.emptyLabel.hidden = (panelController.itemCount > 0);
    panelController.scrollView.hidden = (panelController.itemCount == 0);

    // Position near mouse
    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];
    CGFloat panelW = 360, panelH = 480;

    CGFloat x = mouseLoc.x - panelW / 2;
    CGFloat y = mouseLoc.y - panelH - 20;

    if (x < screenFrame.origin.x) x = screenFrame.origin.x + 10;
    if (x + panelW > NSMaxX(screenFrame)) x = NSMaxX(screenFrame) - panelW - 10;
    if (y < screenFrame.origin.y) y = screenFrame.origin.y + 10;

    [panelController.panel setFrame:NSMakeRect(x, y, panelW, panelH) display:YES];
    [panelController.panel makeKeyAndOrderFront:nil];
    [panelController.panel makeFirstResponder:keyView];
    [NSApp activateIgnoringOtherApps:YES];
}

void hidePanel(void) {
    if (panelController == nil) return;
    [panelController.panel orderOut:nil];
}

int isPanelVisible(void) {
    if (panelController == nil) return 0;
    return panelController.panel.isVisible ? 1 : 0;
}
