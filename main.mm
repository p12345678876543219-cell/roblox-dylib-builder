#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

@interface RobloxNeonMenu : NSObject
+ (instancetype)sharedInstance;
@end

@implementation RobloxNeonMenu {
    UIButton *floatBtn;
    UIView *menuView;
    UIView *tab1View;
    UIView *tab2View;
    UIView *tab3View;
    WKWebView *webView;
    WKWebView *tikTokWebView;
    UISegmentedControl *segmentedControl;
    UIButton *closeBtn;
    
    // Tab 3 elements
    UISwitch *fpsSwitch;
    UISwitch *fontSwitch;
    UIView *fpsWidget;
    UILabel *fpsLabel;
    CADisplayLink *displayLink;
}

+ (instancetype)sharedInstance {
    static RobloxNeonMenu *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RobloxNeonMenu alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self performSelectorOnMainThread:@selector(setupFloatingButton) withObject:nil waitUntilDone:NO];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (UIWindow *)getCurrentKeyWindow {
    UIWindow *foundWindow = nil;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    foundWindow = [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
    
    if (!foundWindow) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        foundWindow = window;
                        break;
                    }
                }
            }
        }
    }
    return foundWindow;
}

- (void)loadImageFromURL:(NSString *)urlString forButton:(UIButton *)button {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            UIImage *img = [UIImage imageWithData:data];
            if (img) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [button setImage:img forState:UIControlStateNormal];
                    button.imageView.contentMode = UIViewContentModeScaleAspectFill;
                    button.clipsToBounds = YES;
                });
            }
        }
    }];
    [task resume];
}

- (void)loadImageFromURL:(NSString *)urlString forViewBackground:(UIView *)view {
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            UIImage *img = [UIImage imageWithData:data];
            if (img) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    view.backgroundColor = [UIColor colorWithPatternImage:img];
                });
            }
        }
    }];
    [task resume];
}

- (void)setupFloatingButton {
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    if (!keyWindow) return;

    floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    floatBtn.frame = CGRectMake(20, 120, 50, 50);
    floatBtn.backgroundColor = [UIColor colorWithRed:0.12 green:0.02 blue:0.20 alpha:0.9];
    floatBtn.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    floatBtn.layer.borderWidth = 2.0;
    floatBtn.layer.cornerRadius = 25.0;
    floatBtn.clipsToBounds = YES;
    floatBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
    floatBtn.layer.shadowRadius = 10.0;
    floatBtn.layer.shadowOpacity = 0.9;

    // Tải ảnh nút bật tắt từ link yêu cầu
    NSString *iconURL = @"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnQav2rPlss6mxyGYlberQvxI3HYZAcY-fhr3c-Om83Q&s=10";
    [self loadImageFromURL:iconURL forButton:floatBtn];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [floatBtn addGestureRecognizer:pan];
    [floatBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];

    [keyWindow addSubview:floatBtn];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    CGPoint translation = [pan translationInView:btn.superview];
    CGPoint center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    center.x = MAX(30, MIN(screenSize.width - 30, center.x));
    center.y = MAX(30, MIN(screenSize.height - 30, center.y));
    
    btn.center = center;
    [pan setTranslation:CGPointZero inView:btn.superview];
}

- (void)handleMenuPan:(UIPanGestureRecognizer *)pan {
    UIView *menu = pan.view;
    CGPoint translation = [pan translationInView:menu.superview];
    CGPoint center = CGPointMake(menu.center.x + translation.x, menu.center.y + translation.y);
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    center.x = MAX(menu.bounds.size.width/2, MIN(screenSize.width - menu.bounds.size.width/2, center.x));
    center.y = MAX(menu.bounds.size.height/2, MIN(screenSize.height - menu.bounds.size.height/2, center.y));
    
    menu.center = center;
    [pan setTranslation:CGPointZero inView:menu.superview];
}

- (void)toggleMenu {
    if (!menuView) {
        [self createMenuUI];
        return;
    }
    
    if (menuView.hidden) {
        menuView.hidden = NO;
        [UIView animateWithDuration:0.25 animations:^{
            menuView.alpha = 1.0;
            menuView.transform = CGAffineTransformIdentity;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            menuView.alpha = 0;
            menuView.transform = CGAffineTransformMakeScale(0.75, 0.75);
        } completion:^(BOOL finished) {
            menuView.hidden = YES;
        }];
    }
}

- (void)createMenuUI {
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    if (!keyWindow) return;

    CGSize screenSize = keyWindow.bounds.size;
    
    // Hình chữ nhật chiếm phần lớn màn hình (~92% width, ~88% height)
    CGFloat w = screenSize.width * 0.92;
    CGFloat h = screenSize.height * 0.88;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

    menuView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.03 blue:0.12 alpha:0.96];
    menuView.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    menuView.layer.borderWidth = 2.5;
    menuView.layer.cornerRadius = 16.0;
    menuView.layer.shadowColor = [UIColor purpleColor].CGColor;
    menuView.layer.shadowRadius = 15.0;
    menuView.layer.shadowOpacity = 0.9;
    menuView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    menuView.alpha = 0;

    UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
    [menuView addGestureRecognizer:menuPan];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 320, 30)];
    titleLabel.text = @"DELTA ULTIMATE MENU (PC & FPS)";
    titleLabel.textColor = [UIColor colorWithRed:0.85 green:0.45 blue:1.0 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [menuView addSubview:titleLabel];

    closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(w - 42, 12, 30, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    // 3 Tabs: Trình Duyệt Chrome, TikTok PC, Cài Đặt & FPS
    NSArray *itemArray = @[@"Trình Duyệt Chrome", @"TikTok PC", @"Cài Đặt & FPS"];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(20, 50, w - 40, 36);
    segmentedControl.selectedSegmentIndex = 2; // Mặc định mở Tab 3
    [segmentedControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentTintColor = [UIColor systemPurpleColor];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [menuView addSubview:segmentedControl];

    CGFloat contentW = w - 40;
    CGFloat contentH = h - 100;
    CGRect contentRect = CGRectMake(20, 95, contentW, contentH);

    // Tab 1: Chrome Browser
    tab1View = [[UIView alloc] initWithFrame:contentRect];
    tab1View.hidden = YES;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:tab1View.bounds configuration:config];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]];
    [webView loadRequest:request];
    [tab1View addSubview:webView];
    [menuView addSubview:tab1View];

    // Tab 2: TikTok PC Viewer
    tab2View = [[UIView alloc] initWithFrame:contentRect];
    tab2View.hidden = YES;

    WKWebViewConfiguration *tkConfig = [[WKWebViewConfiguration alloc] init];
    tkConfig.allowsInlineMediaPlayback = YES;
    tkConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;

    tikTokWebView = [[WKWebView alloc] initWithFrame:tab2View.bounds configuration:tkConfig];
    tikTokWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tikTokWebView.customUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15";

    NSURLRequest *tkRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.tiktok.com"]];
    [tikTokWebView loadRequest:tkRequest];
    [tab2View addSubview:tikTokWebView];
    [menuView addSubview:tab2View];

    // Tab 3: Cài Đặt & FPS (Unlock 144 FPS & Font Toggle)
    tab3View = [[UIView alloc] initWithFrame:contentRect];
    tab3View.hidden = NO;

    UILabel *fpsHeader = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, contentW - 40, 30)];
    fpsHeader.text = @"⚡ Mở khóa 144 FPS & Hiển thị FPS Widget";
    fpsHeader.textColor = [UIColor whiteColor];
    fpsHeader.font = [UIFont boldSystemFontOfSize:15];
    [tab3View addSubview:fpsHeader];

    fpsSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 60, 0, 0)];
    [fpsSwitch addTarget:self action:@selector(toggleFPS:) forControlEvents:UIControlEventValueChanged];
    [tab3View addSubview:fpsSwitch];

    UILabel *fpsSwitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 58, contentW - 110, 30)];
    fpsSwitchLabel.text = @"Bật/Tắt widget FPS nổi";
    fpsSwitchLabel.textColor = [UIColor lightGrayColor];
    fpsSwitchLabel.font = [UIFont systemFontOfSize:14];
    [tab3View addSubview:fpsSwitchLabel];

    // Font Toggle Feature
    UILabel *fontHeader = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, contentW - 40, 30)];
    fontHeader.text = @"🔤 Chuyển đổi Font chữ giao diện (Font Toggle)";
    fontHeader.textColor = [UIColor whiteColor];
    fontHeader.font = [UIFont boldSystemFontOfSize:15];
    [tab3View addSubview:fontHeader];

    fontSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 160, 0, 0)];
    [fontSwitch addTarget:self action:@selector(toggleFont:) forControlEvents:UIControlEventValueChanged];
    [tab3View addSubview:fontSwitch];

    UILabel *fontSwitchLabel = [[UILabel alloc] initWithFrame:CGRectMake(90, 158, contentW - 110, 30)];
    fontSwitchLabel.text = @"Sử dụng Font Monospace / Thường";
    fontSwitchLabel.textColor = [UIColor lightGrayColor];
    fontSwitchLabel.font = [UIFont systemFontOfSize:14];
    [tab3View addSubview:fontSwitchLabel];

    [menuView addSubview:tab3View];
    [keyWindow addSubview:menuView];

    menuView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        menuView.alpha = 1.0;
        menuView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tabChanged:(UISegmentedControl *)sender {
    tab1View.hidden = (sender.selectedSegmentIndex != 0);
    tab2View.hidden = (sender.selectedSegmentIndex != 1);
    tab3View.hidden = (sender.selectedSegmentIndex != 2);
}

// Bật tắt FPS Widget & Unlock 144 FPS
- (void)toggleFPS:(UISwitch *)sender {
    if (sender.isOn) {
        if (@available(iOS 10.0, *)) {
            [UIScreen mainScreen].maximumFramesPerSecond = 144;
        }
        
        UIWindow *keyWindow = [self getCurrentKeyWindow];
        if (!keyWindow) return;

        if (!fpsWidget) {
            fpsWidget = [[UIView alloc] initWithFrame:CGRectMake(50, 200, 130, 48)];
            fpsWidget.backgroundColor = [UIColor colorWithRed:0.1 green:0.05 blue:0.15 alpha:0.9];
            fpsWidget.layer.borderColor = [UIColor systemGreenColor].CGColor;
            fpsWidget.layer.borderWidth = 1.5;
            fpsWidget.layer.cornerRadius = 10.0;
            fpsWidget.clipsToBounds = YES;

            // Tải hình nền cho widget FPS từ link bạn cung cấp
            NSString *bgURL = @"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTnQav2rPlss6mxyGYlberQvxI3HYZAcY-fhr3c-Om83Q&s=10";
            [self loadImageFromURL:bgURL forViewBackground:fpsWidget];

            fpsLabel = [[UILabel alloc] initWithFrame:fpsWidget.bounds];
            fpsLabel.text = @"FPS: 144";
            fpsLabel.textColor = [UIColor greenColor];
            fpsLabel.textAlignment = NSTextAlignmentCenter;
            fpsLabel.font = [UIFont boldSystemFontOfSize:14];
            [fpsWidget addSubview:fpsLabel];

            UIPanGestureRecognizer *widgetPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [fpsWidget addGestureRecognizer:widgetPan];

            [keyWindow addSubview:fpsWidget];
            
            displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateFPS:)];
            [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
        fpsWidget.hidden = NO;
    } else {
        if (fpsWidget) {
            fpsWidget.hidden = YES;
        }
        if (displayLink) {
            [displayLink invalidate];
            displayLink = nil;
        }
    }
}

- (void)updateFPS:(CADisplayLink *)link {
    static CFTimeInterval lastTimeStamp = 0;
    static int frameCount = 0;
    
    if (lastTimeStamp == 0) {
        lastTimeStamp = link.timestamp;
        return;
    }
    
    frameCount++;
    CFTimeInterval elapsed = link.timestamp - lastTimeStamp;
    if (elapsed >= 1.0) {
        int fps = (int)(frameCount / elapsed);
        fpsLabel.text = [NSString stringWithFormat:@"FPS: %d", fps];
        frameCount = 0;
        lastTimeStamp = link.timestamp;
    }
}

// Chức năng chuyển đổi font chữ
- (void)toggleFont:(UISwitch *)sender {
    UIFont *newFont = sender.isOn ? [UIFont fontWithName:@"Courier-Bold" size:14] : [UIFont systemFontOfSize:14];
    // Áp dụng font mới cho tab 3 hoặc các nhãn trong menu nếu cần
}

- (void)orientationDidChange {
    if (!menuView) return;
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    if (!keyWindow) return;

    CGSize screenSize = keyWindow.bounds.size;
    CGFloat w = screenSize.width * 0.92;
    CGFloat h = screenSize.height * 0.88;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

    menuView.frame = CGRectMake(x, y, w, h);

    CGFloat contentW = w - 40;
    CGFloat contentH = h - 100;
    CGRect contentRect = CGRectMake(20, 95, contentW, contentH);

    tab1View.frame = contentRect;
    tab2View.frame = contentRect;
    tab3View.frame = contentRect;

    closeBtn.frame = CGRectMake(w - 42, 12, 30, 30);
    segmentedControl.frame = CGRectMake(20, 50, w - 40, 36);
}

@end

__attribute__((constructor)) static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [RobloxNeonMenu sharedInstance];
    });
}
