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
    WKWebView *webView;
    WKWebView *youtubeWebView;
    UISegmentedControl *segmentedControl;
    UIButton *closeBtn;
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
        }];
    } else {
        [self createMenuUI];
    }
}

- (void)createMenuUI {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    CGSize screenSize = keyWindow.bounds.size;
    BOOL isLandscape = screenSize.width > screenSize.height;

    CGFloat w = isLandscape ? 500 : 320;
    CGFloat h = isLandscape ? 280 : 420;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

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
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 180, 25)];
    titleLabel.text = @"ROBLOX NEON MENU";
    titleLabel.textColor = [UIColor colorWithRed:0.85 green:0.45 blue:1.0 alpha:1.0];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [menuView addSubview:titleLabel];

    // Close Button
    closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(w - 35, 8, 25, 25);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeBtn];

    // Segmented Control (Tabs)
    NSArray *itemArray = @[@"Trình Duyệt Chrome", @"YouTube"];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:itemArray];
    segmentedControl.frame = CGRectMake(15, 38, w - 30, 30);
    segmentedControl.selectedSegmentIndex = 0;
    [segmentedControl addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentTintColor = [UIColor systemPurpleColor];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
    [menuView addSubview:segmentedControl];

    // Content Container
    CGFloat contentW = w - 30;
    CGFloat contentH = h - 80;
    CGRect contentRect = CGRectMake(15, 75, contentW, contentH);

    // Tab 1: Chrome Browser
    tab1View = [[UIView alloc] initWithFrame:contentRect];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:tab1View.bounds configuration:config];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]];
    [webView loadRequest:request];
    [tab1View addSubview:webView];
    [menuView addSubview:tab1View];

    // Tab 2: YouTube Player (Cho phép chạy âm thanh ngầm khi ẩn/đóng Menu)
    tab2View = [[UIView alloc] initWithFrame:contentRect];
    tab2View.hidden = YES;

    WKWebViewConfiguration *ytConfig = [[WKWebViewConfiguration alloc] init];
    ytConfig.allowsInlineMediaPlayback = YES;
    ytConfig.mediaPlaybackAllowsUserAction = NO; // Cho phép video tự phát âm thanh

    youtubeWebView = [[WKWebView alloc] initWithFrame:tab2View.bounds configuration:ytConfig];
    youtubeWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSURLRequest *ytRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.youtube.com"]];
    [youtubeWebView loadRequest:ytRequest];
    [tab2View addSubview:youtubeWebView];
    [menuView addSubview:tab2View];

    [keyWindow addSubview:menuView];

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

- (void)orientationDidChange {
    if (!menuView || !menuView.superview) return;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return;

    CGSize screenSize = keyWindow.bounds.size;
    BOOL isLandscape = screenSize.width > screenSize.height;

    CGFloat w = isLandscape ? 500 : 320;
    CGFloat h = isLandscape ? 280 : 420;
    CGFloat x = (screenSize.width - w) / 2;
    CGFloat y = (screenSize.height - h) / 2;

    menuView.frame = CGRectMake(x, y, w, h);

    CGFloat contentW = w - 30;
    CGFloat contentH = h - 80;
    CGRect contentRect = CGRectMake(15, 75, contentW, contentH);

    tab1View.frame = contentRect;
    tab2View.frame = contentRect;

    closeBtn.frame = CGRectMake(w - 35, 8, 25, 25);
    segmentedControl.frame = CGRectMake(15, 38, w - 30, 30);
}

@end

__attribute__((constructor)) static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [RobloxNeonMenu sharedInstance];
    });
}
