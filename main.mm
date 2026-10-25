#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

// --- 1. Hộp FPS nhỏ gọn, di chuyển được & Sóng âm đồng bộ nhạc YouTube ---
@interface FPSVisualizerView : UIView
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) NSMutableArray<UIView *> *barViews;
- (void)updateBarsWithLevel:(CGFloat)level;
@end

@implementation FPSVisualizerView {
    CADisplayLink *_displayLink;
    NSTimeInterval _lastTimestamp;
    NSInteger _frameCount;
    CGFloat _currentLevel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        self.layer.cornerRadius = 10;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor cyanColor] CGColor];
        self.clipsToBounds = YES;
        
        self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, frame.size.width - 10, 20)];
        self.fpsLabel.textColor = [UIColor greenColor];
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textAlignment = NSTextAlignmentCenter;
        self.fpsLabel.text = @"FPS: 60";
        [self addSubview:self.fpsLabel];
        
        CGFloat barWidth = 4;
        CGFloat spacing = 3;
        int numBars = 5;
        CGFloat startX = (frame.size.width - (numBars * (barWidth + spacing))) / 2;
        
        self.barViews = [NSMutableArray array];
        for (int i = 0; i < numBars; i++) {
            UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(startX + i * (barWidth + spacing), 30, barWidth, 18)];
            bar.backgroundColor = [UIColor systemPinkColor];
            bar.layer.cornerRadius = 2;
            [self addSubview:bar];
            [self.barViews addObject:bar];
        }
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLoop:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint center = self.center;
    self.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
}

- (void)updateLoop:(CADisplayLink *)link {
    if (_lastTimestamp == 0) {
        _lastTimestamp = link.timestamp;
        return;
    }
    _frameCount++;
    NSTimeInterval elapsed = link.timestamp - _lastTimestamp;
    if (elapsed >= 1.0) {
        NSInteger fps = (NSInteger)(_frameCount / elapsed);
        self.fpsLabel.text = [NSString stringWithFormat:@"FPS: %ld", (long)fps];
        _frameCount = 0;
        _lastTimestamp = link.timestamp;
    }
}

- (void)updateBarsWithLevel:(CGFloat)level {
    _currentLevel = level;
    for (int i = 0; i < self.barViews.count; i++) {
        UIView *bar = self.barViews[i];
        CGFloat dynamicHeight = 4 + (_currentLevel / 255.0) * 14 + (arc4random_uniform(6));
        if (dynamicHeight > 20) dynamicHeight = 20;
        if (_currentLevel <= 1.0) dynamicHeight = 4;
        
        CGRect frame = bar.frame;
        frame.size.height = dynamicHeight;
        frame.origin.y = 30 + (18 - dynamicHeight);
        bar.frame = frame;
    }
}
@end

// --- 2. Khai báo trước TweakManager để các class khác nhận diện ---
@interface TweakManager : NSObject
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *mainContainerView;
@property (nonatomic, strong) id mainVC;
@property (nonatomic, strong) FPSVisualizerView *fpsView;

+ (instancetype)sharedInstance;
- (void)setupUI;
- (void)updateAudioVisualizerLevel:(CGFloat)level;
@end

// --- 3. Giao diện chính chứa YouTube tích hợp JS Bridge ---
@interface MainGUIViewController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation MainGUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.95];
    self.view.layer.cornerRadius = 16;
    self.view.layer.borderWidth = 2;
    self.view.layer.borderColor = [[UIColor systemIndigoColor] CGColor];
    self.view.clipsToBounds = YES;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 200, 30)];
    titleLabel.text = @"YouTube Music HUD";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:titleLabel];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 90, 12, 75, 32);
    [self.closeButton setTitle:@"ĐÓNG ✕" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.backgroundColor = [UIColor systemRedColor];
    self.closeButton.layer.cornerRadius = 8;
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [self.closeButton addTarget:self action:@selector(closeGUI) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    WKUserContentController *userController = [[WKUserContentController alloc] init];
    [userController addScriptMessageHandler:self name:@"audioSync"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userController;
    config.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    
    NSString *jsSource = @" \
        (function() { \
            setInterval(function() { \
                var video = document.querySelector('video'); \
                if (!video || video.paused) { \
                    window.webkit.messageHandlers.audioSync.postMessage(0); \
                } else { \
                    var simulatedLevel = 40 + Math.sin(Date.now() / 100) * 30 + Math.random() * 40; \
                    window.webkit.messageHandlers.audioSync.postMessage(simulatedLevel); \
                } \
            }, 80); \
        })(); \
    ";
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsSource injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [userController addUserScript:userScript];
    
    CGFloat webY = 60;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(10, webY, self.view.frame.size.width - 20, self.view.frame.size.height - webY - 10) configuration:config];
    self.webView.layer.cornerRadius = 10;
    self.webView.clipsToBounds = YES;
    
    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"audioSync"]) {
        CGFloat level = [message.body floatValue];
        [[TweakManager sharedInstance] updateAudioVisualizerLevel:level];
    }
}

- (void)closeGUI {
    self.view.superview.hidden = YES;
}

@end

// --- 4. Quản lý hiển thị toàn cục ---
@implementation TweakManager

+ (instancetype)sharedInstance {
    static TweakManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TweakManager alloc] init];
    });
    return sharedInstance;
}

- (void)setupUI {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;
        
        self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.toggleButton.frame = CGRectMake(20, 120, 50, 50);
        self.toggleButton.backgroundColor = [UIColor systemBlueColor];
        [self.toggleButton setTitle:@"YT" forState:UIControlStateNormal];
        [self.toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.toggleButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.toggleButton.layer.cornerRadius = 25;
        self.toggleButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.toggleButton.layer.shadowOpacity = 0.5;
        self.toggleButton.layer.shadowOffset = CGSizeMake(0, 2);
        [self.toggleButton addTarget:self action:@selector(toggleMainGUI) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTogglePan:)];
        [self.toggleButton addGestureRecognizer:pan];
        [keyWindow addSubview:self.toggleButton];
        
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat guiW = screenRect.size.width - 40;
        CGFloat guiH = screenRect.size.height - 100;
        
        self.mainContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 50, guiW, guiH)];
        self.mainContainerView.hidden = YES;
        
        MainGUIViewController *mainVC = [[MainGUIViewController alloc] init];
        self.mainVC = mainVC;
        mainVC.view.frame = self.mainContainerView.bounds;
        [self.mainContainerView addSubview:mainVC.view];
        [keyWindow addSubview:self.mainContainerView];
        
        self.fpsView = [[FPSVisualizerView alloc] initWithFrame:CGRectMake(screenRect.size.width - 130, 120, 110, 55)];
        [keyWindow addSubview:self.fpsView];
    });
}

- (void)toggleMainGUI {
    self.mainContainerView.hidden = !self.mainContainerView.hidden;
}

- (void)handleTogglePan:(UIPanGestureRecognizer * _Nonnull)gesture {
    CGPoint translation = [gesture translationInView:gesture.view.superview];
    CGPoint center = gesture.view.center;
    gesture.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:gesture.view.superview];
}

- (void)updateAudioVisualizerLevel:(CGFloat)level {
    [self.fpsView updateBarsWithLevel:level];
}

@end

__attribute__((constructor)) static void initTweak() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[TweakManager sharedInstance] setupUI];
    });
}
