#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string>
#include <vector>

// ==========================================
// 1. CẤU HÌNH MỤC TIÊU PHIÊN BẢN 1.26.60
// ==========================================

static NSString *const kTargetMinecraftVersion = @"1.26.60";

typedef struct {
    uintptr_t levelRendererRenderOffset;   // Offset hàm render frame / world
    uintptr_t blockSourceGetBlockOffset;     // Offset hàm lấy Block từ tọa độ (x, y, z)
    uintptr_t viewMatrixOffset;            // Offset ma trận View/Projection (nếu lấy trực tiếp)
    BOOL hooksEnabledForTarget;
} MCPEOffsets_1_26_60;

// Điền offset thực tế (tính từ base 0x0 của binary minecraftpe 1.26.60) khi đã dump/phân tích xong
static MCPEOffsets_1_26_60 g_Offsets_1_26_60 = {
    .levelRendererRenderOffset = 0x0,
    .blockSourceGetBlockOffset = 0x0,
    .viewMatrixOffset          = 0x0,
    .hooksEnabledForTarget     = NO
};

// ==========================================
// 2. HELPER: THÔNG TIN GAME & KIỂM TRA BẢN
// ==========================================

NSString* GetMinecraftShortVersion() {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *shortVersion = infoDict[@"CFBundleShortVersionString"];
    return shortVersion ?: @"0.0.0";
}

NSString* GetMinecraftVersionDisplay() {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *shortVersion = infoDict[@"CFBundleShortVersionString"] ?: @"Không rõ";
    NSString *buildVersion = infoDict[@"CFBundleVersion"] ?: @"N/A";
    BOOL matched = [shortVersion isEqualToString:kTargetMinecraftVersion];
    return [NSString stringWithFormat:@"%@ (%@) %@", shortVersion, buildVersion, matched ? @"[TARGET OK]" : @"[MISMATCH]"];
}

BOOL IsTargetVersion1_26_60() {
    return [[GetMinecraftShortVersion() stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            isEqualToString:kTargetMinecraftVersion];
}

NSString* GetMinecraftPlayerName() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *optionsPath = [documentsDirectory stringByAppendingPathComponent:@"games/com.mojang/minecraftpe/options.txt"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:optionsPath]) {
        NSError *error = nil;
        NSString *content = [NSString stringWithContentsOfFile:optionsPath encoding:NSUTF8StringEncoding error:&error];
        if (content && !error) {
            NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            for (NSString *line in lines) {
                if ([line hasPrefix:@"mp_username:"]) {
                    NSString *name = [line substringFromIndex:12];
                    if (name.length > 0) return name;
                }
            }
        }
    }
    return @"Steve (Chưa đăng nhập / Offline)";
}

// ==========================================
// 3. MEMORY & ESP ENGINE CHO 1.26.60
// ==========================================

typedef NS_ENUM(NSInteger, MCPEESPType) {
    MCPEESPTypeIron = 0,
    MCPEESPTypeGold = 1,
    MCPEESPTypeDiamond = 2
};

typedef struct {
    MCPEESPType type;
    CGPoint screenPos;
    float distance;
} ESPProjectedTarget;

static BOOL g_IronESPEnabled = NO;
static BOOL g_GoldESPEnabled = NO;
static BOOL g_DiamondESPEnabled = NO;
static BOOL g_TargetProfileReady = NO;

static inline uintptr_t GetASLRSlide() {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

static inline uintptr_t ResolveTargetAddress(uintptr_t relativeOffset) {
    if (relativeOffset == 0) return 0;
    return GetASLRSlide() + relativeOffset;
}

static inline BOOL SafeReadMemory(uintptr_t address, void *outBuffer, size_t size) {
    if (address == 0 || !outBuffer || size == 0) return NO;
    vm_size_t outSize = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(),
                                         (vm_address_t)address,
                                         (vm_size_t)size,
                                         (vm_address_t)outBuffer,
                                         &outSize);
    return (kr == KERN_SUCCESS && outSize == size);
}

// Gom danh sách mục tiêu Sắt / Vàng / Kim Cương đang bật cho bản 1.26.60
static std::vector<ESPProjectedTarget> CollectActiveESPTargets_1_26_60(CGSize viewSize) {
    std::vector<ESPProjectedTarget> results;
    if (!g_TargetProfileReady) return results;

    // Khi nối dữ liệu quét chunk/entity từ hook 1.26.60:
    // Lọc theo g_IronESPEnabled, g_GoldESPEnabled, g_DiamondESPEnabled và chiếu 3D -> 2D (viewSize).
    (void)viewSize;
    return results;
}

void SetESPState(MCPEESPType type, BOOL enabled) {
    uintptr_t slide = GetASLRSlide();
    switch (type) {
        case MCPEESPTypeIron:
            g_IronESPEnabled = enabled;
            NSLog(@"[1.26.60 ESP] Sắt: %@ | Slide: 0x%lx", enabled ? @"ON" : @"OFF", slide);
            break;
        case MCPEESPTypeGold:
            g_GoldESPEnabled = enabled;
            NSLog(@"[1.26.60 ESP] Vàng: %@ | Slide: 0x%lx", enabled ? @"ON" : @"OFF", slide);
            break;
        case MCPEESPTypeDiamond:
            g_DiamondESPEnabled = enabled;
            NSLog(@"[1.26.60 ESP] Kim Cương: %@ | Slide: 0x%lx", enabled ? @"ON" : @"OFF", slide);
            break;
    }
}

void InitMinecraftHooks_1_26_60() {
    uintptr_t slide = GetASLRSlide();
    if (!IsTargetVersion1_26_60()) {
        g_TargetProfileReady = NO;
        NSLog(@"[1.26.60 Hook] Cảnh báo: Phiên bản hiện tại (%@) khác mục tiêu %@. Tạm khóa hook offset.",
              GetMinecraftShortVersion(), kTargetMinecraftVersion);
        return;
    }

    g_TargetProfileReady = YES;
    uintptr_t renderAddr = ResolveTargetAddress(g_Offsets_1_26_60.levelRendererRenderOffset);
    uintptr_t blockAddr  = ResolveTargetAddress(g_Offsets_1_26_60.blockSourceGetBlockOffset);

    NSLog(@"[1.26.60 Hook] Đã kích hoạt profile 1.26.60 | ASLR Slide: 0x%lx | Render: 0x%lx | BlockSource: 0x%lx",
          slide, renderAddr, blockAddr);

    // Gắn hook thực thi (MSHookFunction / DobbyHook) tại đây khi bạn đã có offset 1.26.60 hợp lệ
    // và đặt g_Offsets_1_26_60.hooksEnabledForTarget = YES.
}

// ==========================================
// 4. LỚP VẼ ESP OVERLAY TRÊN MÀN HÌNH
// ==========================================

@interface MCPEESPOverlayView : UIView
@end

@implementation MCPEESPOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawESPBadgeWithText:(NSString *)text
                       color:(UIColor *)color
                      origin:(CGPoint)origin {
    NSDictionary *attrs = @{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:10],
        NSForegroundColorAttributeName: color
    };
    CGSize textSize = [text sizeWithAttributes:attrs];
    CGRect boxRect = CGRectMake(origin.x, origin.y, textSize.width + 10, textSize.height + 4);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, [[UIColor blackColor] colorWithAlphaComponent:0.65].CGColor);
    CGContextFillRect(ctx, boxRect);

    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextStrokeRect(ctx, boxRect);

    [text drawAtPoint:CGPointMake(origin.x + 5, origin.y + 2) withAttributes:attrs];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;

    CGFloat yCursor = 24.0;
    CGFloat rightEdge = rect.size.width - 14.0;

    // Hiển thị chỉ báo trạng thái từng loại ESP cho 1.26.60
    if (g_IronESPEnabled) {
        NSString *badge = @"IRON ESP [1.26.60]";
        CGFloat w = [badge sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}].width + 10;
        [self drawESPBadgeWithText:badge color:[UIColor lightGrayColor] origin:CGPointMake(rightEdge - w, yCursor)];
        yCursor += 22.0;
    }
    if (g_GoldESPEnabled) {
        NSString *badge = @"GOLD ESP [1.26.60]";
        CGFloat w = [badge sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}].width + 10;
        [self drawESPBadgeWithText:badge color:[UIColor systemYellowColor] origin:CGPointMake(rightEdge - w, yCursor)];
        yCursor += 22.0;
    }
    if (g_DiamondESPEnabled) {
        NSString *badge = @"DIAMOND ESP [1.26.60]";
        CGFloat w = [badge sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:10]}].width + 10;
        [self drawESPBadgeWithText:badge color:[UIColor cyanColor] origin:CGPointMake(rightEdge - w, yCursor)];
        yCursor += 22.0;
    }

    // Vẽ các mục tiêu đã chiếu tọa độ từ thế giới 1.26.60
    std::vector<ESPProjectedTarget> targets = CollectActiveESPTargets_1_26_60(rect.size);
    for (const auto &t : targets) {
        UIColor *c = (t.type == MCPEESPTypeDiamond) ? [UIColor cyanColor] :
                     (t.type == MCPEESPTypeGold)    ? [UIColor systemYellowColor] :
                                                      [UIColor lightGrayColor];
        NSString *label = (t.type == MCPEESPTypeDiamond) ? @"Diamond" :
                          (t.type == MCPEESPTypeGold)    ? @"Gold" : @"Iron";
        NSString *tag = [NSString stringWithFormat:@"%@ (%.0fm)", label, t.distance];
        [self drawESPBadgeWithText:tag color:c origin:t.screenPos];
    }
}

@end

// ==========================================
// 5. GIAO DIỆN MENU & NÚT NỔI (UI OVERLAY)
// ==========================================

@interface MCPEFloatingMenu : NSObject
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *menuContainer;
@property (nonatomic, strong) MCPEESPOverlayView *espOverlay;
@property (nonatomic, strong) UILabel *playerLabel;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UIButton *ironESPButton;
@property (nonatomic, strong) UIButton *goldESPButton;
@property (nonatomic, strong) UIButton *diamondESPButton;
@property (nonatomic, strong) NSTimer *espRefreshTimer;
@property (nonatomic, assign) BOOL isMenuVisible;
+ (instancetype)sharedInstance;
- (void)setupUI;
@end

@implementation MCPEFloatingMenu

+ (instancetype)sharedInstance {
    static MCPEFloatingMenu *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MCPEFloatingMenu alloc] init];
    });
    return instance;
}

- (UIWindow *)getKeyWindow {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

- (UIButton *)createESPToggleButtonWithTitle:(NSString *)title
                                      frame:(CGRect)frame
                                activeColor:(UIColor *)activeColor
                                        tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    btn.tag = tag;
    btn.layer.cornerRadius = 6;
    btn.layer.borderWidth = 1.0;
    btn.layer.borderColor = activeColor.CGColor;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn addTarget:self action:@selector(handleESPToggle:) forControlEvents:UIControlEventTouchUpInside];
    [self updateToggleButtonAppearance:btn title:title enabled:NO activeColor:activeColor];
    return btn;
}

- (void)updateToggleButtonAppearance:(UIButton *)btn
                               title:(NSString *)title
                             enabled:(BOOL)enabled
                         activeColor:(UIColor *)activeColor {
    NSString *stateText = enabled ? @"ON" : @"OFF";
    [btn setTitle:[NSString stringWithFormat:@"%@: %@", title, stateText] forState:UIControlStateNormal];
    if (enabled) {
        btn.backgroundColor = [activeColor colorWithAlphaComponent:0.35];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        btn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
        [btn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    }
}

- (void)setupUI {
    UIWindow *window = [self getKeyWindow];
    if (!window) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupUI];
        });
        return;
    }

    self.espOverlay = [[MCPEESPOverlayView alloc] initWithFrame:window.bounds];
    self.espOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:self.espOverlay];

    // 1. Nút bật/tắt menu có hình
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleButton.frame = CGRectMake(30, 80, 56, 56);
    self.toggleButton.layer.cornerRadius = 28;
    self.toggleButton.clipsToBounds = YES;
    self.toggleButton.layer.borderWidth = 2.0;
    self.toggleButton.layer.borderColor = [UIColor colorWithRed:0.45 green:0.85 blue:0.45 alpha:1.0].CGColor;

    UIImage *iconImg = [UIImage imageNamed:@"menu_icon.png"];
    if (!iconImg) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"menu_icon" ofType:@"png"];
        iconImg = [UIImage imageWithContentsOfFile:bundlePath];
    }

    if (iconImg) {
        [self.toggleButton setImage:iconImg forState:UIControlStateNormal];
        self.toggleButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        self.toggleButton.backgroundColor = [UIColor systemGreenColor];
        [self.toggleButton setTitle:@"MC" forState:UIControlStateNormal];
    }

    [self.toggleButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.toggleButton addGestureRecognizer:pan];

    // 2. Khung Menu chính
    CGFloat menuWidth = 295;
    CGFloat menuHeight = 298;
    self.menuContainer = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width - menuWidth) / 2,
                                                                  (window.bounds.size.height - menuHeight) / 2,
                                                                  menuWidth,
                                                                  menuHeight)];
    self.menuContainer.backgroundColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.10 alpha:0.94];
    self.menuContainer.layer.cornerRadius = 12;
    self.menuContainer.layer.borderWidth = 1.5;
    self.menuContainer.layer.borderColor = [UIColor colorWithRed:0.45 green:0.85 blue:0.45 alpha:1.0].CGColor;
    self.menuContainer.hidden = YES;
    self.isMenuVisible = NO;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, menuWidth - 30, 22)];
    titleLabel.text = @"MCPE 1.26.60 INFO & ESP";
    titleLabel.textColor = [UIColor colorWithRed:0.55 green:0.95 blue:0.55 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.menuContainer addSubview:titleLabel];

    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(15, 36, menuWidth - 30, 1)];
    divider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    [self.menuContainer addSubview:divider];

    self.playerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 44, menuWidth - 30, 22)];
    self.playerLabel.textColor = [UIColor whiteColor];
    self.playerLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [self.menuContainer addSubview:self.playerLabel];

    self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 68, menuWidth - 30, 22)];
    self.versionLabel.textColor = [UIColor lightGrayColor];
    self.versionLabel.font = [UIFont systemFontOfSize:12];
    [self.menuContainer addSubview:self.versionLabel];

    UILabel *espSectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 96, menuWidth - 30, 18)];
    espSectionLabel.text = @"ESP TÀI NGUYÊN (TARGET 1.26.60)";
    espSectionLabel.textColor = [UIColor colorWithRed:0.65 green:0.85 blue:1.0 alpha:1.0];
    espSectionLabel.font = [UIFont boldSystemFontOfSize:11];
    [self.menuContainer addSubview:espSectionLabel];

    CGFloat btnWidth = menuWidth - 30;
    CGFloat btnHeight = 32;

    self.ironESPButton = [self createESPToggleButtonWithTitle:@"ESP Sắt"
                                                      frame:CGRectMake(15, 118, btnWidth, btnHeight)
                                                activeColor:[UIColor lightGrayColor]
                                                        tag:MCPEESPTypeIron];
    [self.menuContainer addSubview:self.ironESPButton];

    self.goldESPButton = [self createESPToggleButtonWithTitle:@"ESP Vàng"
                                                      frame:CGRectMake(15, 156, btnWidth, btnHeight)
                                                activeColor:[UIColor systemYellowColor]
                                                        tag:MCPEESPTypeGold];
    [self.menuContainer addSubview:self.goldESPButton];

    self.diamondESPButton = [self createESPToggleButtonWithTitle:@"ESP Kim Cương"
                                                         frame:CGRectMake(15, 194, btnWidth, btnHeight)
                                                   activeColor:[UIColor cyanColor]
                                                           tag:MCPEESPTypeDiamond];
    [self.menuContainer addSubview:self.diamondESPButton];

    UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    refreshBtn.frame = CGRectMake(15, 246, btnWidth, 34);
    refreshBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.65 blue:0.30 alpha:1.0];
    refreshBtn.layer.cornerRadius = 6;
    [refreshBtn setTitle:@"Cập nhật thông tin" forState:UIControlStateNormal];
    [refreshBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    refreshBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [refreshBtn addTarget:self action:@selector(refreshInfo) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:refreshBtn];

    [self refreshInfo];

    [window addSubview:self.menuContainer];
    [window addSubview:self.toggleButton];

    self.espRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                           target:self
                                                         selector:@selector(tickESPOverlay)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)handleESPToggle:(UIButton *)sender {
    MCPEESPType type = (MCPEESPType)sender.tag;
    if (type == MCPEESPTypeIron) {
        SetESPState(MCPEESPTypeIron, !g_IronESPEnabled);
        [self updateToggleButtonAppearance:self.ironESPButton
                                     title:@"ESP Sắt"
                                   enabled:g_IronESPEnabled
                               activeColor:[UIColor lightGrayColor]];
    } else if (type == MCPEESPTypeGold) {
        SetESPState(MCPEESPTypeGold, !g_GoldESPEnabled);
        [self updateToggleButtonAppearance:self.goldESPButton
                                     title:@"ESP Vàng"
                                   enabled:g_GoldESPEnabled
                               activeColor:[UIColor systemYellowColor]];
    } else if (type == MCPEESPTypeDiamond) {
        SetESPState(MCPEESPTypeDiamond, !g_DiamondESPEnabled);
        [self updateToggleButtonAppearance:self.diamondESPButton
                                     title:@"ESP Kim Cương"
                                   enabled:g_DiamondESPEnabled
                               activeColor:[UIColor cyanColor]];
    }
    [self.espOverlay setNeedsDisplay];
}

- (void)tickESPOverlay {
    if (g_IronESPEnabled || g_GoldESPEnabled || g_DiamondESPEnabled) {
        [self.espOverlay setNeedsDisplay];
    }
}

- (void)refreshInfo {
    self.playerLabel.text = [NSString stringWithFormat:@"👤 Player: %@", GetMinecraftPlayerName()];
    self.versionLabel.text = [NSString stringWithFormat:@"🎮 Phiên bản: %@", GetMinecraftVersionDisplay()];
}

- (void)toggleMenu {
    self.isMenuVisible = !self.isMenuVisible;
    if (self.isMenuVisible) {
        [self refreshInfo];
    }
    self.menuContainer.hidden = !self.isMenuVisible;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    UIView *superview = recognizer.view.superview;
    CGPoint translation = [recognizer translationInView:superview];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:superview];
}

@end

// ==========================================
// 6. ĐIỂM KHỞI CHẠY DYLIB (CONSTRUCTOR)
// ==========================================

__attribute__((constructor)) static void EntryPoint() {
    InitMinecraftHooks_1_26_60();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[MCPEFloatingMenu sharedInstance] setupUI];
    });
}
