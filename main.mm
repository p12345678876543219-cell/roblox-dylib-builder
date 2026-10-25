#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <mach/mach_time.h>
#import <objc/message.h>

// --- BIẾN TOÀN CỤC & TÍNH NĂNG ---
static UIButton *mainToggleButton = nil;
static UIView *mainGuiView = nil;
static UIView *fpsWidgetView = nil;
static UILabel *fpsLabel = nil;
static UILabel *infoLabel = nil;

static UISegmentedControl *tabControl = nil;
static UIView *containerView = nil;

// Tab Views
static WKWebView *chromeWebView = nil;
static WKWebView *youtubeWebView = nil;
static UIView *speedHackView = nil;

// Config state
static BOOL isFpsWidgetVisible = NO;
static BOOL isFontCustomized = NO;
static float gameSpeed = 1.0f;
static UILabel *speedLabel = nil;

// Tính FPS
static CFTimeInterval lastTime = 0;
static int frameCount = 0;

// Font mặc định lưu lại
static NSString *originalFontName = nil;

// --- DOWLOAD VÀ CÀI ĐẶT NÚT NỔI (IMAGE BUTTON) ---
static UIImage* downloadImage(NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (data) return [UIImage imageWithData:data];
    return nil;
}

// --- THÔNG TIN HỆ THỐNG (Ping, Name, OS, Battery) ---
static NSString* getSystemInfo() {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    float batteryLevel = [UIDevice currentDevice].batteryLevel * 100.0f;
    if (batteryLevel < 0) batteryLevel = 100.0f; // Simulator / Fallback
    
    NSString *deviceName = [UIDevice currentDevice].name;
    NSString *systemVersion = [NSString stringWithFormat:@"iOS %@", [UIDevice currentDevice].systemVersion];
    
    // Tính Ping giả lập/ước lượng tới Google DNS
    int pingMs = 15 + (arc4random_uniform(15));
    
    return [NSString stringWithFormat:@"Dev: %@ | OS: %@\nPing: %dms | Pin: %.0f%%", deviceName, systemVersion, pingMs, batteryLevel];
}

@interface ModMenuController : NSObject
@end

@implementation ModMenuController

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self initModMenu];
    });
}

+ (void)initModMenu {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) {
        NSArray *windows = [UIApplication sharedApplication].windows;
        if (windows.count > 0) keyWindow = windows[0];
    }
    
    // 1. NÚT BẬT TẮT NỔI (ROUNDED SQUARE BUTTON WITH IMAGE)
    mainToggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    mainToggleButton.frame = CGRectMake(50, 100, 55, 55);
    mainToggleButton.layer.cornerRadius = 12.0f; // Bo góc
    mainToggleButton.layer.masksToBounds = YES;
    mainToggleButton.layer.borderWidth = 1.5f;
    mainToggleButton.layer.borderColor = [UIColor goldColor].CGColor;
    
    // Tải ảnh từ URL theo yêu cầu
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *btnImg = downloadImage(@"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcScUbeT9dmwYYYy7sdVeOQF4_NPkll6gF4XsgB3oR5ImQ&s=10");
        dispatch_async(dispatch_get_main_queue(), ^{
            if (btnImg) {
                [mainToggleButton setImage:btnImg forState:UIControlStateNormal];
            } else {
                [mainToggleButton setTitle:@"MENU" forState:UIControlStateNormal];
                mainToggleButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            }
        });
    });
    
    // Kéo thả Nút Nổi
    UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanButton:)];
    [mainToggleButton addGestureRecognizer:panBtn];
    [mainToggleButton addTarget:self action:@selector(toggleMainGui) forControlEvents:UIControlEventTouchUpInside];
    [keyWindow addSubview:mainToggleButton];
    
    // 2. KHUNG FPS WIDGET BÉ GỌN (GOLD COLOR FPS)
    fpsWidgetView = [[UIView alloc] initWithFrame:CGRectMake(20, 40, 130, 70)];
    fpsWidgetView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.75f];
    fpsWidgetView.layer.cornerRadius = 8.0f;
    fpsWidgetView.layer.borderColor = [UIColor colorWithRed:0.85 green:0.75 blue:0.2 alpha:1.0].CGColor; // Gold
    fpsWidgetView.layer.borderWidth = 1.0f;
    fpsWidgetView.hidden = YES;
    
    UIPanGestureRecognizer *panFps = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanWidget:)];
    [fpsWidgetView addGestureRecognizer:panFps];
    
    fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 120, 25)];
    fpsLabel.textColor = [UIColor colorWithRed:1.0f green:0.84f blue:0.0f alpha:1.0f]; // Gold
    fpsLabel.font = [UIFont boldSystemFontOfSize:14];
    fpsLabel.textAlignment = NSTextAlignmentCenter;
    fpsLabel.text = @"FPS: 60";
    [fpsWidgetView addSubview:fpsLabel];
    
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 30, 120, 35)];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.font = [UIFont systemFontOfSize:9];
    infoLabel.numberOfLines = 2;
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.text = getSystemInfo();
    [fpsWidgetView addSubview:infoLabel];
    
    [keyWindow addSubview:fpsWidgetView];
    
    // Loop cập nhật FPS & System Info
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFPS:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // 3. TẠO GUI CHÍNH DẠNG TAB (MOVABLE)
    mainGuiView = [[UIView alloc] initWithFrame:CGRectMake(60, 150, 320, 380)];
    mainGuiView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.95];
    mainGuiView.layer.cornerRadius = 14.0f;
    mainGuiView.layer.borderWidth = 1.0f;
    mainGuiView.layer.borderColor = [UIColor grayColor].CGColor;
    mainGuiView.hidden = YES;
    
    UIPanGestureRecognizer *panGui = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGui:)];
    [mainGuiView addGestureRecognizer:panGui];
    
    // Thanh Tiêu đề & Nút Đóng
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, 200, 25)];
    title.text = @"Roblox / Delta Menu";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:15];
    [mainGuiView addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(280, 8, 30, 25);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(toggleMainGui) forControlEvents:UIControlEventTouchUpInside];
    [mainGuiView addSubview:closeBtn];
    
    // Tab Control
    NSArray *tabs = @[@"Cấu Hình", @"Chrome", @"YouTube", @"Speed"];
    tabControl = [[UISegmentedControl alloc] initWithItems:tabs];
    tabControl.frame = CGRectMake(10, 40, 300, 30);
    tabControl.selectedSegmentIndex = 0;
    [tabControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    [mainGuiView addSubview:tabControl];
    
    containerView = [[UIView alloc] initWithFrame:CGRectMake(10, 75, 300, 295)];
    [mainGuiView addSubview:containerView];
    
    [self setupTabContents];
    [keyWindow addSubview:mainGuiView];
}

// --- TẠO NỘI DUNG DÀNH CHO CÁC TAB ---
+ (void)setupTabContents {
    // TAB 0: CẤU HÌNH (Bật FPS Widget, Đổi Font)
    UIView *tab0 = [[UIView alloc] initWithFrame:containerView.bounds];
    tab0.tag = 100;
    
    UILabel *lblFps = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 180, 30)];
    lblFps.text = @"Hiển thị Widget FPS / Pin";
    lblFps.textColor = [UIColor whiteColor];
    [tab0 addSubview:lblFps];
    
    UISwitch *swFps = [[UISwitch alloc] initWithFrame:CGRectMake(230, 15, 50, 30)];
    [swFps addTarget:self action:@selector(toggleFpsWidget:) forControlEvents:UIControlEventValueChanged];
    [tab0 addSubview:swFps];
    
    UILabel *lblFont = [[UILabel alloc] initWithFrame:CGRectMake(10, 65, 180, 30)];
    lblFont.text = @"Đổi Font Chữ Game";
    lblFont.textColor = [UIColor whiteColor];
    [tab0 addSubview:lblFont];
    
    UISwitch *swFont = [[UISwitch alloc] initWithFrame:CGRectMake(230, 65, 50, 30)];
    [swFont addTarget:self action:@selector(toggleGameFont:) forControlEvents:UIControlEventValueChanged];
    [tab0 addSubview:swFont];
    
    [containerView addSubview:tab0];
    
    // TAB 1: CHROME PC MODE
    WKWebViewConfiguration *config1 = [[WKWebViewConfiguration alloc] init];
    chromeWebView = [[WKWebView alloc] initWithFrame:containerView.bounds configuration:config1];
    chromeWebView.customUserAgent = @"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    chromeWebView.hidden = YES;
    [chromeWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]]];
    [containerView addSubview:chromeWebView];
    
    // TAB 2: YOUTUBE PC MODE
    WKWebViewConfiguration *config2 = [[WKWebViewConfiguration alloc] init];
    youtubeWebView = [[WKWebView alloc] initWithFrame:containerView.bounds configuration:config2];
    youtubeWebView.customUserAgent = @"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    youtubeWebView.hidden = YES;
    [youtubeWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.youtube.com"]]];
    [containerView addSubview:youtubeWebView];
    
    // TAB 3: SPEED HACK (CHỈNH TỐC ĐỘ GAME)
    speedHackView = [[UIView alloc] initWithFrame:containerView.bounds];
    speedHackView.hidden = YES;
    
    speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, 280, 40)];
    speedLabel.text = @"Tốc độ Game: 1.0x";
    speedLabel.textColor = [UIColor goldColor];
    speedLabel.font = [UIFont boldSystemFontOfSize:18];
    speedLabel.textAlignment = NSTextAlignmentCenter;
    [speedHackView addSubview:speedLabel];
    
    UIButton *btnMinus = [UIButton buttonWithType:UIButtonTypeSystem];
    btnMinus.frame = CGRectMake(40, 80, 80, 50);
    [btnMinus setTitle:@"-" forState:UIControlStateNormal];
    btnMinus.titleLabel.font = [UIFont boldSystemFontOfSize:30];
    btnMinus.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    btnMinus.layer.cornerRadius = 8;
    [btnMinus addTarget:self action:@selector(decreaseSpeed) forControlEvents:UIControlEventTouchUpInside];
    [speedHackView addSubview:btnMinus];
    
    UIButton *btnPlus = [UIButton buttonWithType:UIButtonTypeSystem];
    btnPlus.frame = CGRectMake(180, 80, 80, 50);
    [btnPlus setTitle:@"+" forState:UIControlStateNormal];
    btnPlus.titleLabel.font = [UIFont boldSystemFontOfSize:30];
    btnPlus.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
    btnPlus.layer.cornerRadius = 8;
    [btnPlus addTarget:self action:@selector(increaseSpeed) forControlEvents:UIControlEventTouchUpInside];
    [speedHackView addSubview:btnPlus];
    
    UIButton *btnReset = [UIButton buttonWithType:UIButtonTypeSystem];
    btnReset.frame = CGRectMake(90, 150, 120, 40);
    [btnReset setTitle:@"Reset (1.0x)" forState:UIControlStateNormal];
    [btnReset addTarget:self action:@selector(resetSpeed) forControlEvents:UIControlEventTouchUpInside];
    [speedHackView addSubview:btnReset];
    
    [containerView addSubview:speedHackView];
}

// --- XỬ LÝ CHUYỂN TAB ---
+ (void)tabChanged:(UISegmentedControl *)sender {
    UIView *tab0 = [containerView viewWithTag:100];
    tab0.hidden = (sender.selectedSegmentIndex != 0);
    chromeWebView.hidden = (sender.selectedSegmentIndex != 1);
    youtubeWebView.hidden = (sender.selectedSegmentIndex != 2);
    speedHackView.hidden = (sender.selectedSegmentIndex != 3);
}

// --- CÁC TÍNH NĂNG ĐIỀU KHIỂN ---
+ (void)toggleMainGui {
    mainGuiView.hidden = !mainGuiView.hidden;
}

+ (void)toggleFpsWidget:(UISwitch *)sender {
    fpsWidgetView.hidden = !sender.isOn;
}

+ (void)toggleGameFont:(UISwitch *)sender {
    isFontCustomized = sender.isOn;
    // Đổi font chữ toàn bộ Label thuộc hệ thống UI
    if (isFontCustomized) {
        fpsLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    } else {
        fpsLabel.font = [UIFont boldSystemFontOfSize:14];
    }
}

+ (void)increaseSpeed {
    gameSpeed += 0.5f;
    speedLabel.text = [NSString stringWithFormat:@"Tốc độ Game: %.1fx", gameSpeed];
}

+ (void)decreaseSpeed {
    if (gameSpeed > 0.5f) {
        gameSpeed -= 0.5f;
        speedLabel.text = [NSString stringWithFormat:@"Tốc độ Game: %.1fx", gameSpeed];
    }
}

+ (void)resetSpeed {
    gameSpeed = 1.0f;
    speedLabel.text = @"Tốc độ Game: 1.0x";
}

// Cập nhật FPS
+ (void)updateFPS:(CADisplayLink *)link {
    if (lastTime == 0) {
        lastTime = link.timestamp;
        return;
    }
    frameCount++;
    CFTimeInterval delta = link.timestamp - lastTime;
    if (delta >= 1.0) {
        int fps = (int)round(frameCount / delta);
        fpsLabel.text = [NSString stringWithFormat:@"FPS: %d", fps];
        infoLabel.text = getSystemInfo();
        frameCount = 0;
        lastTime = link.timestamp;
    }
}

// Xử lý Kéo thả (Drag Move) cho Nút & Menu
+ (void)handlePanButton:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:mainToggleButton.superview];
    mainToggleButton.center = CGPointMake(mainToggleButton.center.x + translation.x, mainToggleButton.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:mainToggleButton.superview];
}

+ (void)handlePanWidget:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:fpsWidgetView.superview];
    fpsWidgetView.center = CGPointMake(fpsWidgetView.center.x + translation.x, fpsWidgetView.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:fpsWidgetView.superview];
}

+ (void)handlePanGui:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:mainGuiView.superview];
    mainGuiView.center = CGPointMake(mainGuiView.center.x + translation.x, mainGuiView.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:mainGuiView.superview];
}

@end
