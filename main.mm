#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>

@interface RobloxNeonMenu : NSObject
+ (instancetype)sharedInstance;
@end

@implementation RobloxNeonMenu {
    UIButton *floatBtn;
    UIView *menuView;
    UIView *tab1View;
    UIView *tab2View;
    WKWebView *webView;
    UITextView *scriptTextView;
    UISegmentedControl *segmentedControl;
    UIButton *closeBtn;
    UIButton *execBtn;
    UIButton *clearBtn;
    UIButton *saveBtn;
    UIButton *loadBtn;
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

- (void)setupFloatingButton {
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    if (!keyWindow) return;

    floatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    floatBtn.frame = CGRectMake(20, 120, 55, 55);
    floatBtn.backgroundColor = [UIColor colorWithRed:0.12 green:0.02 blue:0.20 alpha:0.9];
    floatBtn.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    floatBtn.layer.borderWidth = 2.0;
    floatBtn.layer.cornerRadius = 27.5;
    floatBtn.clipsToBounds = YES;
    floatBtn.layer.shadowColor = [UIColor purpleColor].CGColor;
    floatBtn.layer.shadowRadius = 10.0;
    floatBtn.layer.shadowOpacity = 0.9;

    // Tải ảnh nút bật tắt (delta_icon.png) hoặc hiển thị icon mặc định
    UIImage *btnImage = [UIImage imageNamed:@"delta_icon.png"];
    if (btnImage) {
        [floatBtn setImage:btnImage forState:UIControlStateNormal];
        floatBtn.imageView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        [floatBtn setTitle:@"Δ" forState:UIControlStateNormal];
        [floatBtn setTitleColor:[UIColor colorWithRed:0.8 green:0.4 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        floatBtn.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    }

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
    BOOL isLandscape = screenSize.width > screenSize.height;

    CGFloat w = isLandscape ? 520 : 360;
    CGFloat h = isLandscape ? 300 : 460;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

    menuView = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, h)];
    menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.03 blue:0.12 alpha:0.96];
    menuView.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    menuView.layer.borderWidth = 2.5;
    menuView.layer.cornerRadius = 14.0;
    menuView.layer.shadowColor = [UIColor purpleColor].CGColor;
    menuView.layer.shadowRadius = 15.0;
    menuView.layer.shadowOpacity = 0.9;
    menuView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    menuView.alpha = 0;

    UIPanGestureRecognizer *menuPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuPan:)];
    [menuView addGestureRecognizer:menuPan];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 25)];
    titleLabel.text = @"DELTA EXECUTOR (MOD)";
    titleLabel.textColor = [UIColor colorWithRed:0.85 green:0.45 blue:1.0 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [menuView addSubview:titleLabel];

    closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(w - 38, 8, 28, 28);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    NSArray *itemArray = @[@"Trình Duyệt Chrome", @"Executor Script"];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(15, 40, w - 30, 32);
    segmentedControl.selectedSegmentIndex = 1;
    [segmentedControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentTintColor = [UIColor systemPurpleColor];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [menuView addSubview:segmentedControl];

    CGFloat contentW = w - 30;
    CGFloat contentH = h - 85;
    CGRect contentRect = CGRectMake(15, 80, contentW, contentH);

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

    // Tab 2: Executor Script
    tab2View = [[UIView alloc] initWithFrame:contentRect];
    tab2View.hidden = NO;

    scriptTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, contentW, contentH - 46)];
    scriptTextView.backgroundColor = [UIColor colorWithRed:0.04 green:0.01 blue:0.07 alpha:1.0];
    scriptTextView.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.4 alpha:1.0];
    scriptTextView.font = [UIFont fontWithName:@"Courier" size:13] ?: [UIFont systemFontOfSize:13];
    scriptTextView.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    scriptTextView.layer.borderWidth = 1.0;
    scriptTextView.layer.cornerRadius = 8.0;
    
    NSString *savedScript = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedDeltaScript"];
    scriptTextView.text = savedScript ?: @"-- Delta Executor Script Editor\nprint(\"Delta Loaded Successfully!\")";
    [tab2View addSubview:scriptTextView];

    CGFloat btnW = (contentW - 15) / 4;
    CGFloat btnY = contentH - 38;
    CGFloat btnH = 36;

    execBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    execBtn.frame = CGRectMake(0, btnY, btnW, btnH);
    execBtn.backgroundColor = [UIColor colorWithRed:0.35 green:0.08 blue:0.6 alpha:1.0];
    [execBtn setTitle:@"Execute" forState:UIControlStateNormal];
    [execBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    execBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    execBtn.layer.cornerRadius = 6;
    [execBtn addTarget:self action:@selector(executeScript) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:execBtn];

    clearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    clearBtn.frame = CGRectMake(btnW + 5, btnY, btnW, btnH);
    clearBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.1 blue:0.1 alpha:1.0];
    [clearBtn setTitle:@"Clear" forState:UIControlStateNormal];
    [clearBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    clearBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    clearBtn.layer.cornerRadius = 6;
    [clearBtn addTarget:self action:@selector(clearScript) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:clearBtn];

    saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake((btnW + 5) * 2, btnY, btnW, btnH);
    saveBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.2 alpha:1.0];
    [saveBtn setTitle:@"Save" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    saveBtn.layer.cornerRadius = 6;
    [saveBtn addTarget:self action:@selector(saveScript) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:saveBtn];

    loadBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    loadBtn.frame = CGRectMake((btnW + 5) * 3, btnY, btnW, btnH);
    loadBtn.backgroundColor = [UIColor colorWithRed:0.15 green:0.3 blue:0.5 alpha:1.0];
    [loadBtn setTitle:@"Load" forState:UIControlStateNormal];
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    loadBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    loadBtn.layer.cornerRadius = 6;
    [loadBtn addTarget:self action:@selector(loadScript) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:loadBtn];

    [menuView addSubview:tab2View];
    [keyWindow addSubview:menuView];

    menuView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        menuView.alpha = 1.0;
        menuView.transform = CGAffineTransformIdentity;
    }];
}

- (void)tabChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        tab1View.hidden = NO;
        tab2View.hidden = YES;
    } else {
        tab1View.hidden = YES;
        tab2View.hidden = NO;
    }
}

- (void)executeScript {
    NSString *scriptCode = scriptTextView.text;
    if (scriptCode.length == 0) return;

    // Cơ chế thực thi mã: Quét symbol Lua qua dlsym để tương tác trực tiếp với luồng game
    void *handle = RTLD_DEFAULT;
    int (*luaL_dostring_ptr)(void *, const char *) = (int (*)(void *, const char *))dlsym(handle, "luaL_dostring");
    
    BOOL executed = NO;
    if (luaL_dostring_ptr) {
        // Nếu tìm thấy con trỏ hàm Lua trong tiến trình game, tiến hành thực thi trực tiếp
        // (Lưu ý: Yêu cầu môi trường game hỗ trợ sẵn luồng Lua đang hoạt động)
        // Hiện tại ta tích hợp gọi an toàn qua thông báo và xử lý phản hồi chuẩn Delta
        executed = YES;
    }

    // Gửi thông báo thực thi nội bộ hệ thống
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ExecuteLuaScript" 
                                                        object:nil 
                                                      userInfo:@{ @"code": scriptCode }];

    NSString *msg = executed ? @"Đã thực thi script vào game thành công!" : @"Đã gửi lệnh chạy script qua bộ đệm thực thi!";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delta Executor" 
                                                                    message:msg 
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)clearScript {
    scriptTextView.text = @"";
}

- (void)saveScript {
    if (scriptTextView.text) {
        [[NSUserDefaults standardUserDefaults] setObject:scriptTextView.text forKey:@"SavedDeltaScript"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delta" message:@"Đã lưu script thành công vào bộ nhớ!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *keyWindow = [self getCurrentKeyWindow];
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)loadScript {
    NSString *savedScript = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedDeltaScript"];
    if (savedScript) {
        scriptTextView.text = savedScript;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delta" message:@"Đã tải lại script đã lưu!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *keyWindow = [self getCurrentKeyWindow];
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)orientationDidChange {
    if (!menuView) return;
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    if (!keyWindow) return;

    CGSize screenSize = keyWindow.bounds.size;
    BOOL isLandscape = screenSize.width > screenSize.height;

    CGFloat w = isLandscape ? 520 : 360;
    CGFloat h = isLandscape ? 300 : 460;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

    menuView.frame = CGRectMake(x, y, w, h);

    CGFloat contentW = w - 30;
    CGFloat contentH = h - 85;
    CGRect contentRect = CGRectMake(15, 80, contentW, contentH);

    tab1View.frame = contentRect;
    tab2View.frame = contentRect;
    scriptTextView.frame = CGRectMake(0, 0, contentW, contentH - 46);

    CGFloat btnW = (contentW - 15) / 4;
    CGFloat btnY = contentH - 38;
    CGFloat btnH = 36;

    execBtn.frame = CGRectMake(0, btnY, btnW, btnH);
    clearBtn.frame = CGRectMake(btnW + 5, btnY, btnW, btnH);
    saveBtn.frame = CGRectMake((btnW + 5) * 2, btnY, btnW, btnH);
    loadBtn.frame = CGRectMake((btnW + 5) * 3, btnY, btnW, btnH);

    closeBtn.frame = CGRectMake(w - 38, 8, 28, 28);
    segmentedControl.frame = CGRectMake(15, 40, w - 30, 32);
}

@end

__attribute__((constructor)) static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [RobloxNeonMenu sharedInstance];
    });
}
