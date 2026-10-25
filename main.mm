#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

@interface RobloxNeonMenu : NSObject
+ (instancetype)sharedInstance;
@end

@implementation RobloxNeonMenu {
    UIButton *floatBtn;
    UIView *menuView;
    UILabel *fpsLabel;
    UILabel *clockLabel;
    UILabel *ipLabel;
    UILabel *pingLabel;
    CADisplayLink *displayLink;
    CFTimeInterval lastTime;
    int frameCount;
    WKWebView *webView;
    UIView *browserContainer;
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
    }
    return self;
}

- (void)setupFloatingButton {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    floatBtn.frame = CGRectMake(20, 120, 55, 55);
    floatBtn.backgroundColor = [UIColor colorWithRed:0.12 green:0.02 blue:0.20 alpha:0.85];
    floatBtn.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    floatBtn.layer.borderWidth = 2.0;
    floatBtn.layer.cornerRadius = 27.5;
    floatBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
    floatBtn.layer.shadowRadius = 10.0;
    floatBtn.layer.shadowOpacity = 0.9;
    [floatBtn setTitle:@"MOD" forState:UIControlStateNormal];
    [floatBtn setTitleColor:[UIColor colorWithRed:0.8 green:0.4 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    floatBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];

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

- (void)toggleMenu {
    if (menuView && menuView.superview) {
        [UIView animateWithDuration:0.25 animations:^{
            menuView.alpha = 0;
            menuView.transform = CGAffineTransformMakeScale(0.75, 0.75);
        } completion:^(BOOL finished) {
            [menuView removeFromSuperview];
            menuView = nil;
            [displayLink invalidate];
            displayLink = nil;
        }];
    } else {
        [self createMenuUI];
    }
}

- (void)createMenuUI {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    CGFloat w = 320;
    CGFloat h = 440;
    CGFloat x = (keyWindow.bounds.size.width - w) / 2;
    CGFloat y = (keyWindow.bounds.size.height - h) / 2;

    menuView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    menuView.backgroundColor = [UIColor colorWithRed:0.06 green:0.01 blue:0.10 alpha:0.95];
    menuView.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    menuView.layer.borderWidth = 2.5;
    menuView.layer.cornerRadius = 16.0;
    menuView.layer.shadowColor = [UIColor purpleColor].CGColor;
    menuView.layer.shadowRadius = 15.0;
    menuView.layer.shadowOpacity = 0.9;
    menuView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    menuView.alpha = 0;

    // Title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, w - 50, 30)];
    titleLabel.text = @"ROBLOX NEON MENU";
    titleLabel.textColor = [UIColor colorWithRed:0.85 green:0.45 blue:1.0 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [menuView addSubview:titleLabel];

    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(w - 40, 12, 28, 28);

    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    // Divider
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(15, 48, w - 30, 1)];
    line.backgroundColor = [UIColor systemPurpleColor];
    [menuView addSubview:line];

    CGFloat startY = 60;

    // 1. FPS Label
    fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, startY, w - 40, 25)];
    fpsLabel.textColor = [UIColor whiteColor];
    fpsLabel.font = [UIFont systemFontOfSize:14];
    fpsLabel.text = @"FPS: Đang tính...";
    [menuView addSubview:fpsLabel];

    // 2. Clock Label
    clockLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, startY + 30, w - 40, 25)];
    clockLabel.textColor = [UIColor whiteColor];
    clockLabel.font = [UIFont systemFontOfSize:14];
    [menuView addSubview:clockLabel];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateClock) userInfo:nil repeats:YES];
    [self updateClock];

    // 3. IP Address Label
    ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, startY + 60, w - 40, 25)];
    ipLabel.textColor = [UIColor whiteColor];
    ipLabel.font = [UIFont systemFontOfSize:14];
    ipLabel.text = @"IP: Đang tải...";
    [menuView addSubview:ipLabel];
    [self fetchIPAddress];

    // 4. Ping Label
    pingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, startY + 90, w - 40, 25)];
    pingLabel.textColor = [UIColor whiteColor];
    pingLabel.font = [UIFont systemFontOfSize:14];
    pingLabel.text = @"Ping: Đang đo...";
    [menuView addSubview:pingLabel];
    [self measurePing];

    // 5. Chrome Browser Button
    UIButton *browserBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    browserBtn.frame = CGRectMake(20, startY + 130, w - 40, 42);
    browserBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.05 blue:0.45 alpha:0.9];
    [browserBtn setTitle:@"Mở Trình Duyệt Chrome (Mini)" forState:UIControlStateNormal];
    [browserBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    browserBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    browserBtn.layer.cornerRadius = 8;
    browserBtn.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    browserBtn.layer.borderWidth = 1.0;
    [browserBtn addTarget:self action:@selector(openBrowser) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:browserBtn];

    [keyWindow addSubview:menuView];

    [UIView animateWithDuration:0.25 animations:^{
        menuView.alpha = 1.0;
        menuView.transform = CGAffineTransformIdentity;
    }];

    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tickFPS:)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tickFPS:(CADisplayLink *)link {
    if (lastTime == 0) {
        lastTime = link.timestamp;
        return;
    }
    frameCount++;
    CFTimeInterval elapsed = link.timestamp - lastTime;
    if (elapsed >= 1.0) {
        int fps = (int)(frameCount / elapsed);
        fpsLabel.text = [NSString stringWithFormat:@"FPS: %d", fps];
        frameCount = 0;
        lastTime = link.timestamp;
    }
}

- (void)updateClock {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss - dd/MM/yyyy"];
    clockLabel.text = [NSString stringWithFormat:@"Thời gian: %@", [formatter stringFromDate:[NSDate date]]];
}

- (void)fetchIPAddress {
    NSURL *url = [NSURL URLWithString:@"https://api.ipify.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && !error) {
            NSString *ip = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (ip) {
                    ipLabel.text = [NSString stringWithFormat:@"IP: %@", [ip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                ipLabel.text = @"IP: Không tải được";
            });
        }
    }];
    [task resume];
}

- (void)measurePing {
    NSDate *start = [NSDate date];
    NSURL *url = [NSURL URLWithString:@"https://www.google.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSTimeInterval latency = [[NSDate date] timeIntervalSinceDate:start] * 1000;
        dispatch_async(dispatch_get_main_queue(), ^{
            pingLabel.text = [NSString stringWithFormat:@"Ping: %.0f ms", latency];
        });
    }];
    [task resume];
}

- (void)openBrowser {
    if (browserContainer && browserContainer.superview) return;

    CGFloat w = menuView.bounds.size.width - 20;
    CGFloat h = 185;
    browserContainer = [[UIView alloc] initWithFrame:CGRectMake(10, 230, w, h)];
    browserContainer.backgroundColor = [UIColor blackColor];
    browserContainer.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    browserContainer.layer.borderWidth = 1.0;
    browserContainer.layer.cornerRadius = 8.0;
    browserContainer.clipsToBounds = YES;

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 30, w, h - 30) configuration:config];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]];
    [webView loadRequest:request];
    [browserContainer addSubview:webView];

    UIButton *closeBrowserBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBrowserBtn.frame = CGRectMake(w - 55, 2, 50, 26);
    [closeBrowserBtn setTitle:@"Đóng" forState:UIControlStateNormal];
    [closeBrowserBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBrowserBtn addTarget:self action:@selector(closeBrowser) forControlEvents:UIControlEventTouchUpInside];
    [browserContainer addSubview:closeBrowserBtn];

    [menuView addSubview:browserContainer];
}

- (void)closeBrowser {
    [browserContainer removeFromSuperview];
    browserContainer = nil;
    webView = nil;
}

@end

__attribute__((constructor)) static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [RobloxNeonMenu sharedInstance];
    });
}
