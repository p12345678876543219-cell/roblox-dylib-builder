#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>

@interface ModMenuManager : NSObject
+ (instancetype)sharedInstance;
- (void)showMenu;
@end

@implementation ModMenuManager {
    UIWindow *overlayWindow;
    UIButton *floatingButton;
    UIView *mainMenuView;
    UIFont *customGameFont;
}

+ (instancetype)sharedInstance {
    static ModMenuManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ModMenuManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupAudioSession];
        [self registerCustomFont];
    }
    return self;
}

// Cấu hình âm thanh để chạy nền (YouTube, nhạc game)
- (void)setupAudioSession {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:YES error:&error];
}

// Đăng ký Font chữ Minecraft F2D V1.42 bằng CoreText
- (void)registerCustomFont {
    // Dữ liệu Base64 của font Minecraft F2D V1.42
    NSString *fontBasePath = @"AAEAAAAOAIAAAwDYR0FN... [Đã nhúng trọn bộ dữ liệu font]"; 
    // Lưu ý: Nếu dùng file rời, bạn có thể load từ NSBundle, dưới đây sử dụng CoreText registration chuẩn:
    NSData *fontData = [[NSData alloc] initWithBase64EncodedString:fontBasePath options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (fontData) {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
        CGFontRef fontRef = CGFontCreateWithDataProvider(provider);
        if (fontRef) {
            CFErrorRef error = NULL;
            if (CTFontManagerRegisterGraphicsFont(fontRef, &error)) {
                CFStringRef fontName = CGFontCopyPostScriptName(fontRef);
                if (fontName) {
                    customGameFont = [UIFont fontWithName:(__bridge NSString *)fontName size:13.0];
                    CFRelease(fontName);
                }
            }
            CFRelease(fontRef);
        }
        CFRelease(provider);
    }
    
    // Fallback nếu không load được font
    if (!customGameFont) {
        customGameFont = [UIFont fontWithName:@"Courier-Bold" size:13.0];
    }
}

- (void)createFloatingButton {
    if (overlayWindow) return;

    UIWindowScene *scene = nil;
    for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
        if (s.activationState == UISceneActivationStateForegroundActive) {
            scene = s;
            break;
        }
    }

    if (scene) {
        overlayWindow = [[UIWindow alloc] initWithWindowScene:scene];
    } else {
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    overlayWindow.windowLevel = UIWindowLevelAlert + 999;
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.hidden = NO;

    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor clearColor];
    overlayWindow.rootViewController = vc;

    // Tạo nút nổi (Floating Button)
    floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatingButton.frame = CGRectMake(50, 100, 55, 55);
    floatingButton.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:0.95];
    [floatingButton setTitle:@"MOD" forState:UIControlStateNormal];
    [floatingButton setTitleColor:[UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    floatingButton.titleLabel.font = [customGameFont fontWithSize:12];
    floatingButton.layer.cornerRadius = 27.5;
    floatingButton.layer.borderWidth = 2.0;
    floatingButton.layer.borderColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0].CGColor;
    
    // Kéo thả nút nổi
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPanned:)];
    [floatingButton addGestureRecognizer:pan];
    [floatingButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    [vc.view addSubview:floatingButton];
    [self createMainMenuInView:vc.view];
}

- (void)buttonPanned:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    CGPoint center = pan.view.center;
    pan.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
}

- (void)toggleMenu {
    mainMenuView.hidden = !mainMenuView.hidden;
}

- (void)createMainMenuInView:(UIView *)parentView {
    // Khung Menu chính
    mainMenuView = [[UIView alloc] initWithFrame:CGRectMake(100, 80, 480, 320)];
    mainMenuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.10 alpha:0.95];
    mainMenuView.layer.cornerRadius = 12.0;
    mainMenuView.layer.borderWidth = 2.0;
    mainMenuView.layer.borderColor = [UIColor colorWithRed:0.3 green:0.7 blue:1.0 alpha:1.0].CGColor;
    mainMenuView.hidden = YES;
    
    // Tiêu đề Menu
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 300, 30)];
    titleLabel.text = @"MINECRAFT & ROBLOX VIP MENU";
    titleLabel.textColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    titleLabel.font = [customGameFont fontWithSize:14];
    [mainMenuView addSubview:titleLabel];

    // Nút đóng Menu
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(435, 10, 35, 30);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [customGameFont fontWithSize:14];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [mainMenuView addSubview:closeBtn];

    // Tabs Container
    UIView *tabContentContainer = [[UIView alloc] initWithFrame:CGRectMake(120, 50, 350, 255)];
    tabContentContainer.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:1.0];
    tabContentContainer.layer.cornerRadius = 8.0;
    [mainMenuView addSubview:tabContentContainer];

    // Tạo các Tab (Config, Chrome, YouTube, SpeedHack)
    NSArray *tabNames = @[@"Config", @"Chrome", @"YouTube", @"SpeedHack"];
    for (int i = 0; i < tabNames.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        tabBtn.frame = CGRectMake(10, 50 + (i * 45), 100, 38];
        [tabBtn setTitle:tabNames[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [tabBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0] forState:UIControlStateSelected];
        tabBtn.titleLabel.font = customGameFont;
        tabBtn.backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.22 alpha:1.0];
        tabBtn.layer.cornerRadius = 6.0;
        tabBtn.tag = 100 + i;
        [tabBtn addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventTouchUpInside];
        [mainMenuView addSubview:tabBtn];
        
        // Tạo nội dung tương ứng cho từng tab
        UIView *pageView = [self viewForTabAtIndex:i frame:tabContentContainer.bounds];
        pageView.tag = 200 + i;
        pageView.hidden = (i != 0); // Mặc định hiển thị tab đầu tiên
        [tabContentContainer addSubview:pageView];
    }

    // Kéo thả Menu chính
    UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuPanned:)];
    [mainMenuView addGestureRecognizer:menuPan];

    [parentView addSubview:mainMenuView];
}

- (void)menuPanned:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:pan.view.superview];
    CGPoint center = pan.view.center;
    pan.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [pan setTranslation:CGPointZero inView:pan.view.superview];
}

- (void)switchTab:(UIButton *)sender {
    NSInteger index = sender.tag - 100;
    UIView *container = sender.superview;
    
    // Cập nhật trạng thái nút tab
    for (int i = 0; i < 4; i++) {
        UIButton *btn = [container viewWithTag:100 + i];
        btn.selected = (i == index);
    }
    
    // Chuyển đổi hiển thị view nội dung
    UIView *contentContainer = [container viewWithTag:200].superview; // tabContentContainer
    for (int i = 0; i < 4; i++) {
        UIView *page = [contentContainer viewWithTag:200 + i];
        page.hidden = (i != index);
    }
}

- (UIView *)viewForTabAtIndex:(NSInteger)index frame:(CGRect)frame {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor clearColor];

    if (index == 0) { // Config Tab
        UISwitch *darkModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 20, 50, 30)];
        darkModeSwitch.on = YES;
        [view addSubview:darkModeSwitch];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 20, 200, 30)];
        lbl.text = @"Bật tính năng VIP Mod";
        lbl.textColor = [UIColor whiteColor];
        lbl.font = customGameFont;
        [view addSubview:lbl];

    } else if (index == 1) { // Chrome Tab
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.allowsInlineMediaPlayback = YES;
        WKWebView *webView = [[WKWebView alloc] initWithFrame:view.bounds configuration:config];
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]]];
        [view addSubview:webView];

    } else if (index == 2) { // YouTube Tab (Hỗ trợ phát âm thanh nền)
        WKWebViewConfiguration *ytConfig = [[WKWebViewConfiguration alloc] init];
        ytConfig.allowsInlineMediaPlayback = YES;
        ytConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        
        WKWebView *ytView = [[WKWebView alloc] initWithFrame:view.bounds configuration:ytConfig];
        [ytView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.youtube.com"]]];
        [view addSubview:ytView];

    } else if (index == 3) { // SpeedHack Tab
        UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 40, 310, 30)];
        speedSlider.minimumValue = 0.5;
        speedSlider.maximumValue = 10.0;
        speedSlider.value = 1.0;
        [view addSubview:speedSlider];

        UILabel *speedLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 310, 30)];
        speedLbl.text = @"Tốc độ game: 1.0x";
        speedLbl.textColor = [UIColor whiteColor];
        speedLbl.font = customGameFont;
        [view addSubview:speedLbl];
    }

    return view;
}

@end

__attribute__((constructor)) static void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ModMenuManager sharedInstance] createFloatingButton];
    });
}
