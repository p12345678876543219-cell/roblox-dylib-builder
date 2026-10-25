#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>

@interface ModMenuManager : NSObject
+ (instancetype)sharedInstance;
- (void)showMenu;
@end

@interface ModMenuWindow : UIWindow
@end

@implementation ModMenuWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subview in self.subviews) {
        if (!subview.isHidden && subview.alpha > 0.01 && [subview pointInside:[self convertPoint:point toView:subview] withEvent:event]) {
            return YES;
        }
    }
    return NO;
}
@end

@interface ModMenuViewController : UIViewController <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) UIView *configView;
@property (nonatomic, strong) WKWebView *chromeWebView;
@property (nonatomic, strong) WKWebView *youtubeWebView;
@property (nonatomic, strong) UIView *speedHackView;
@property (nonatomic, strong) UIButton *activeTabButton;
@end

@implementation ModMenuViewController {
    UIButton *floatingButton;
    UIView *menuPanel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupFloatingButton];
    [self setupMenuPanel];
}

- (void)setupFloatingButton {
    floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatingButton.frame = CGRectMake(20, 100, 50, 50);
    floatingButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.9];
    floatingButton.layer.cornerRadius = 25;
    floatingButton.layer.borderWidth = 2.0;
    floatingButton.layer.borderColor = [UIColor systemGreenColor].CGColor;
    [floatingButton setTitle:@"MOD" forState:UIControlStateNormal];
    [floatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    floatingButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [floatingButton addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [floatingButton addGestureRecognizer:pan];
    
    [self.view addSubview:floatingButton];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    CGPoint center = recognizer.view.center;
    recognizer.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGRect frame = floatingButton.frame;
        CGFloat screenWidth = self.view.bounds.size.width;
        CGFloat screenHeight = self.view.bounds.size.height;
        
        if (frame.origin.x < screenWidth / 2) {
            frame.origin.x = 15;
        } else {
            frame.origin.x = screenWidth - frame.size.width - 15;
        }
        if (frame.origin.y < 40) frame.origin.y = 40;
        if (frame.origin.y > screenHeight - frame.size.height - 40) frame.origin.y = screenHeight - frame.size.height - 40;
        
        [UIView animateWithDuration:0.3 animations:^{
            self->floatingButton.frame = frame;
        }];
    }
}

- (void)floatingButtonTapped:(UIButton *)sender {
    menuPanel.hidden = !menuPanel.hidden;
}

- (void)setupMenuPanel {
    CGFloat panelWidth = 420;
    CGFloat panelHeight = 280;
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    menuPanel = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - panelWidth) / 2, (screenHeight - panelHeight) / 2, panelWidth, panelHeight)];
    menuPanel.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:0.95];
    menuPanel.layer.cornerRadius = 14;
    menuPanel.layer.borderWidth = 1.5;
    menuPanel.layer.borderColor = [UIColor systemGreenColor].CGColor;
    menuPanel.hidden = YES;
    
    // Tiêu đề Menu
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, panelWidth - 50, 30)];
    titleLabel.text = @"MINECRAFT MOD MENU v1.42";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [menuPanel addSubview:titleLabel];
    
    // Nút Đóng (X)
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(panelWidth - 35, 10, 25, 25);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(floatingButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [menuPanel addSubview:closeBtn];
    
    // Các Tab Chức năng
    CGFloat tabY = 45;
    NSArray *tabs = @[@"Config", @"Chrome", @"YouTube", @"SpeedHack"];
    CGFloat tabWidth = (panelWidth - 30) / tabs.count;
    
    for (int i = 0; i < tabs.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        tabBtn.frame = CGRectMake(15 + i * tabWidth, tabY, tabWidth, 30);
        [tabBtn setTitle:tabs[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [tabBtn setTitleColor:[UIColor systemGreenColor] forState:UIControlStateSelected];
        tabBtn.titleLabel.font = [UIFont systemFontOfSize:12];
        tabBtn.tag = 100 + i;
        [tabBtn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [menuPanel addSubview:tabBtn];
        if (i == 0) {
            tabBtn.selected = YES;
            self.activeTabButton = tabBtn;
        }
    }
    
    // Khu vực chứa nội dung các Tab
    CGFloat contentY = 80;
    CGFloat contentHeight = panelHeight - contentY - 15;
    CGFloat contentWidth = panelWidth - 30;
    
    // 1. Tab Config
    self.configView = [[UIView alloc] initWithFrame:CGRectMake(15, contentY, contentWidth, contentHeight)];
    UILabel *cfgLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, contentWidth - 80, 25)];
    cfgLbl.text = @"[+] Godmode (Bất tử)";
    cfgLbl.textColor = [UIColor whiteColor];
    cfgLbl.font = [UIFont systemFontOfSize:12];
    [self.configView addSubview:cfgLbl];
    
    UISwitch *godModeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(contentWidth - 60, 8, 0, 0)];
    [godModeSwitch setOn:YES];
    [self.configView addSubview:godModeSwitch];
    [menuPanel addSubview:self.configView];
    
    // 2. Tab Chrome (Trình duyệt web)
    WKWebViewConfiguration *chromeCfg = [[WKWebViewConfiguration alloc] init];
    self.chromeWebView = [[WKWebView alloc] initWithFrame:CGRectMake(15, contentY, contentWidth, contentHeight) configuration:chromeCfg];
    self.chromeWebView.navigationDelegate = self;
    self.chromeWebView.hidden = YES;
    [self.chromeWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com"]]];
    [menuPanel addSubview:self.chromeWebView];
    
    // 3. Tab YouTube (Hỗ trợ phát nhạc chạy ngầm)
    WKWebViewConfiguration *ytCfg = [[WKWebViewConfiguration alloc] init];
    ytCfg.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        ytCfg.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    self.youtubeWebView = [[WKWebView alloc] initWithFrame:CGRectMake(15, contentY, contentWidth, contentHeight) configuration:ytCfg];
    self.youtubeWebView.navigationDelegate = self;
    self.youtubeWebView.hidden = YES;
    [self.youtubeWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.youtube.com"]]];
    [menuPanel addSubview:self.youtubeWebView];
    
    // Kích hoạt Audio Session cho YouTube chạy ngầm
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // 4. Tab SpeedHack (Tốc độ game)
    self.speedHackView = [[UIView alloc] initWithFrame:CGRectMake(15, contentY, contentWidth, contentHeight)];
    self.speedHackView.hidden = YES;
    UILabel *speedLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, contentWidth, 20)];
    speedLbl.text = @"Game Speed Multiplier: 1.0x";
    speedLbl.textColor = [UIColor whiteColor];
    speedLbl.font = [UIFont systemFontOfSize:12];
    [self.speedHackView addSubview:speedLbl];
    
    UISlider *speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 60, contentWidth, 30)];
    speedSlider.minimumValue = 0.5;
    speedSlider.maximumValue = 5.0;
    speedSlider.value = 1.0;
    [self.speedHackView addSubview:speedSlider];
    [menuPanel addSubview:self.speedHackView];
    
    [self.view addSubview:menuPanel];
}

- (void)tabTapped:(UIButton *)sender {
    self.activeTabButton.selected = NO;
    sender.selected = YES;
    self.activeTabButton = sender;
    
    self.configView.hidden = YES;
    self.chromeWebView.hidden = YES;
    self.youtubeWebView.hidden = YES;
    self.speedHackView.hidden = YES;
    
    NSInteger index = sender.tag - 100;
    if (index == 0) self.configView.hidden = NO;
    else if (index == 1) self.chromeWebView.hidden = NO;
    else if (index == 2) self.youtubeWebView.hidden = NO;
    else if (index == 3) self.speedHackView.hidden = NO;
}

@end

@implementation ModMenuManager {
    ModMenuWindow *overlayWindow;
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
        [self performSelectorOnMainThread:@selector(setupWindow) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (void)setupWindow {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    UIWindowLevel level = keyWindow ? keyWindow.windowLevel + 1 : 999999.0;
    
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                overlayWindow = [[ModMenuWindow alloc] initWithWindowScene:scene];
                break;
            }
        }
    }
    if (!overlayWindow) {
        overlayWindow = [[ModMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }
    
    overlayWindow.windowLevel = level;
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.rootViewController = [[ModMenuViewController alloc] init];
    overlayWindow.hidden = NO;
}

- (void)showMenu {
    // Menu hiển thị tự động qua UIWindow và RootViewController
}

@end

__attribute__((constructor)) static void initModMenu() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ModMenuManager sharedInstance];
    });
}
