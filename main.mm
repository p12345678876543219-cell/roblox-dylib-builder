#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <dlfcn.h>
#include <string>
#include <fstream>

// ==========================================
// 1. HELPER: LẤY THÔNG TIN MINECRAFT PE
// ==========================================

// Lấy phiên bản Minecraft từ Info.plist của ứng dụng
NSString* GetMinecraftVersion() {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *shortVersion = infoDict[@"CFBundleShortVersionString"];
    NSString *buildVersion = infoDict[@"CFBundleVersion"];
    if (shortVersion) {
        return [NSString stringWithFormat:@"%@ (Build %@)", shortVersion, buildVersion ?: @"N/A"];
    }
    return @"Không xác định";
}

// Đọc tên người chơi từ file options.txt của Minecraft PE trên iOS
NSString* GetMinecraftPlayerName() {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    
    // Đường dẫn chuẩn lưu cấu hình của Minecraft Bedrock iOS
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
// 2. HOOK ENGINE (CƠ BẢN CHO MCPE)
// ==========================================

uintptr_t GetBaseAddress() {
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// Ví dụ hàm Hook C++ bằng Substrate / Dobby (nếu link thư viện) hoặc patch memory trực tiếp
void InitMinecraftHooks() {
    uintptr_t baseAddr = GetBaseAddress();
    NSLog(@"[MCPE Hook] Base Address minecraftpe: 0x%lx", baseAddr);
    
    // Bạn có thể đặt offset hàm của Minecraft PE tại đây để hook
    // Ví dụ: uintptr_t getPlayerNameOffset = baseAddr + 0x1234567;
}

// ==========================================
// 3. GIAO DIỆN MENU & NÚT NỔI (UI OVERLAY)
// ==========================================

@interface MCPEFloatingMenu : NSObject
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *menuContainer;
@property (nonatomic, strong) UILabel *playerLabel;
@property (nonatomic, strong) UILabel *versionLabel;
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

- (void)setupUI {
    UIWindow *window = [self getKeyWindow];
    if (!window) {
        // Thử lại nếu game chưa render xong cửa sổ chính
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self setupUI];
        });
        return;
    }

    // 1. Tạo nút bật/tắt menu có hình ảnh nhân vật
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.toggleButton.frame = CGRectMake(30, 80, 56, 56);
    self.toggleButton.layer.cornerRadius = 28;
    self.toggleButton.clipsToBounds = YES;
    self.toggleButton.layer.borderWidth = 2.0;
    self.toggleButton.layer.borderColor = [UIColor colorWithRed:0.45 green:0.85 blue:0.45 alpha:1.0].CGColor;
    
    // Nạp ảnh icon (Đặt file tên "menu_icon.png" vào thư mục gốc của file .ipa khi đóng gói)
    UIImage *iconImg = [UIImage imageNamed:@"menu_icon.png"];
    if (!iconImg) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"menu_icon" ofType:@"png"];
        iconImg = [UIImage imageWithContentsOfFile:bundlePath];
    }
    
    if (iconImg) {
        [self.toggleButton setImage:iconImg forState:UIControlStateNormal];
        self.toggleButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        // Màu nền dự phòng nếu chưa chép file menu_icon.png vào IPA
        self.toggleButton.backgroundColor = [UIColor systemGreenColor];
        [self.toggleButton setTitle:@"MC" forState:UIControlStateNormal];
    }

    // Sự kiện bấm để bật/tắt menu
    [self.toggleButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // Sự kiện kéo thả nút đi khắp màn hình
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.toggleButton addGestureRecognizer:pan];

    // 2. Tạo khung Menu chính
    CGFloat menuWidth = 280;
    CGFloat menuHeight = 165;
    self.menuContainer = [[UIView alloc] initWithFrame:CGRectMake((window.bounds.size.width - menuWidth) / 2,
                                                                  (window.bounds.size.height - menuHeight) / 2,
                                                                  menuWidth,
                                                                  menuHeight)];
    self.menuContainer.backgroundColor = [UIColor colorWithRed:0.10 green:0.12 blue:0.10 alpha:0.92];
    self.menuContainer.layer.cornerRadius = 12;
    self.menuContainer.layer.borderWidth = 1.5;
    self.menuContainer.layer.borderColor = [UIColor colorWithRed:0.45 green:0.85 blue:0.45 alpha:1.0].CGColor;
    self.menuContainer.hidden = YES;
    self.isMenuVisible = NO;

    // Tiêu đề Menu
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, menuWidth - 30, 24)];
    titleLabel.text = @"MINECRAFT PE INFO MENU";
    titleLabel.textColor = [UIColor colorWithRed:0.55 green:0.95 blue:0.55 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:15];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.menuContainer addSubview:titleLabel];

    // Đường kẻ ngăn cách
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(15, 42, menuWidth - 30, 1)];
    divider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    [self.menuContainer addSubview:divider];

    // Hiển thị Tên Player
    self.playerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 55, menuWidth - 30, 24)];
    self.playerLabel.textColor = [UIColor whiteColor];
    self.playerLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.menuContainer addSubview:self.playerLabel];

    // Hiển thị Phiên bản Minecraft
    self.versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 85, menuWidth - 30, 24)];
    self.versionLabel.textColor = [UIColor lightGrayColor];
    self.versionLabel.font = [UIFont systemFontOfSize:13];
    [self.menuContainer addSubview:self.versionLabel];

    // Nút làm mới dữ liệu (Refresh)
    UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    refreshBtn.frame = CGRectMake(15, 120, menuWidth - 30, 32);
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
}

- (void)refreshInfo {
    NSString *playerName = GetMinecraftPlayerName();
    NSString *mcVersion = GetMinecraftVersion();
    
    self.playerLabel.text = [NSString stringWithFormat:@"👤 Player: %@", playerName];
    self.versionLabel.text = [NSString stringWithFormat:@"🎮 Phiên bản: %@", mcVersion];
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
// 4. ĐIỂM KHỞI CHẠY DYLIB (CONSTRUCTOR)
// ==========================================

__attribute__((constructor)) static void EntryPoint() {
    InitMinecraftHooks();
    
    // Đợi 3 giây sau khi mở game để UIKit khởi tạo xong màn hình rồi mới gắn nút
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[MCPEFloatingMenu sharedInstance] setupUI];
    });
}
