#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

#pragma mark - Audio message proxy (prevents WKWebView retain cycle)

@interface AudioSyncMessageProxy : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> delegate;
@end

@implementation AudioSyncMessageProxy
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController
                  didReceiveScriptMessage:message];
}
@end

#pragma mark - FPS / audio-level visualizer

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
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = UIColor.cyanColor.CGColor;
        self.clipsToBounds = YES;

        _fpsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _fpsLabel.text = @"FPS: --";
        _fpsLabel.textColor = UIColor.greenColor;
        _fpsLabel.font = [UIFont monospacedDigitSystemFontOfSize:12
                                                          weight:UIFontWeightBold];
        _fpsLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_fpsLabel];

        _barViews = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) {
            UIView *bar = [[UIView alloc] initWithFrame:CGRectZero];
            bar.backgroundColor = UIColor.systemPinkColor;
            bar.layer.cornerRadius = 2.0;
            [self addSubview:bar];
            [_barViews addObject:bar];
        }

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window && !_displayLink) {
        _lastTimestamp = 0;
        _frameCount = 0;
        _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                   selector:@selector(updateLoop:)];
        [_displayLink addToRunLoop:NSRunLoop.mainRunLoop
                           forMode:NSRunLoopCommonModes];
    } else if (!self.window && _displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.bounds);
    _fpsLabel.frame = CGRectMake(4, 3, width - 8, 20);

    CGFloat barWidth = 5.0;
    CGFloat spacing = 4.0;
    CGFloat totalWidth = 5 * barWidth + 4 * spacing;
    CGFloat startX = (width - totalWidth) / 2.0;
    CGFloat availableHeight = MAX(8.0, CGRectGetHeight(self.bounds) - 29.0);

    for (NSInteger i = 0; i < self.barViews.count; i++) {
        UIView *bar = self.barViews[i];
        CGFloat height = MIN(availableHeight, MAX(4.0, CGRectGetHeight(bar.frame)));
        bar.frame = CGRectMake(startX + i * (barWidth + spacing),
                               CGRectGetHeight(self.bounds) - height - 4.0,
                               barWidth, height);
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *parent = self.superview;
    if (!parent) return;

    CGPoint translation = [gesture translationInView:parent];
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;

    CGFloat halfW = CGRectGetWidth(self.bounds) / 2.0;
    CGFloat halfH = CGRectGetHeight(self.bounds) / 2.0;
    center.x = MIN(MAX(halfW, center.x), CGRectGetWidth(parent.bounds) - halfW);
    center.y = MIN(MAX(halfH, center.y), CGRectGetHeight(parent.bounds) - halfH);
    self.center = center;

    [gesture setTranslation:CGPointZero inView:parent];
}

- (void)updateLoop:(CADisplayLink *)link {
    if (_lastTimestamp == 0) {
        _lastTimestamp = link.timestamp;
        return;
    }

    _frameCount++;
    NSTimeInterval elapsed = link.timestamp - _lastTimestamp;
    if (elapsed >= 1.0) {
        NSInteger fps = (NSInteger)round((double)_frameCount / elapsed);
        _fpsLabel.text = [NSString stringWithFormat:@"FPS: %ld", (long)fps];
        _frameCount = 0;
        _lastTimestamp = link.timestamp;
    }
}

- (void)updateBarsWithLevel:(CGFloat)level {
    _currentLevel = MIN(255.0, MAX(0.0, level));

    for (NSInteger i = 0; i < self.barViews.count; i++) {
        UIView *bar = self.barViews[i];
        CGFloat variation = (CGFloat)arc4random_uniform(5);
        CGFloat height = 4.0 + (_currentLevel / 255.0) * 14.0 + variation;
        height = MIN(18.0, height);
        if (_currentLevel <= 1.0) height = 4.0;

        CGRect frame = bar.frame;
        frame.size.height = height;
        frame.origin.y = CGRectGetHeight(self.bounds) - height - 4.0;
        bar.frame = frame;
    }
}

- (void)dealloc {
    [_displayLink invalidate];
}

@end

#pragma mark - Main YouTube web panel

@class TweakManager;

@interface MainGUIViewController : UIViewController <WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) AudioSyncMessageProxy *messageProxy;
@end

@interface TweakManager : NSObject
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *mainContainerView;
@property (nonatomic, strong) MainGUIViewController *mainVC;
@property (nonatomic, strong) FPSVisualizerView *fpsView;
+ (instancetype)sharedInstance;
- (void)setupUI;
- (void)toggleMainGUI;
- (void)updateAudioVisualizerLevel:(CGFloat)level;
@end

@implementation MainGUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.96];
    self.view.layer.cornerRadius = 16.0;
    self.view.layer.borderWidth = 2.0;
    self.view.layer.borderColor = UIColor.systemIndigoColor.CGColor;
    self.view.clipsToBounds = YES;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.tag = 1001;
    titleLabel.text = @"YouTube Music HUD";
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [self.view addSubview:titleLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"ĐÓNG ✕" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.closeButton.backgroundColor = UIColor.systemRedColor;
    self.closeButton.layer.cornerRadius = 8.0;
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    [self.closeButton addTarget:self
                         action:@selector(closeGUI)
               forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];

    WKUserContentController *userController = [[WKUserContentController alloc] init];
    self.messageProxy = [[AudioSyncMessageProxy alloc] init];
    self.messageProxy.delegate = self;
    [userController addScriptMessageHandler:self.messageProxy name:@"audioSync"];

    // This reports a simulated activity level while a video is playing.
    // It does not read YouTube's actual audio samples.
    NSString *jsSource =
    @"(function(){"
     "if (window.__audioSyncTimer) clearInterval(window.__audioSyncTimer);"
     "window.__audioSyncTimer = setInterval(function(){"
     " var video = document.querySelector('video');"
     " var level = (!video || video.paused || video.ended) ? 0 : "
     " (40 + Math.sin(Date.now()/100)*30 + Math.random()*40);"
     " try { window.webkit.messageHandlers.audioSync.postMessage(level); } "
     " catch(e) {}"
     "}, 150);"
     "})();";

    WKUserScript *userScript =
        [[WKUserScript alloc] initWithSource:jsSource
                               injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                            forMainFrameOnly:YES];
    [userController addUserScript:userScript];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = userController;
    config.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
    }

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.layer.cornerRadius = 10.0;
    self.webView.clipsToBounds = YES;
    [self.view addSubview:self.webView];

    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com"];
    if (url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat height = CGRectGetHeight(self.view.bounds);

    UILabel *titleLabel = [self.view viewWithTag:1001];
    titleLabel.frame = CGRectMake(12, 12, MAX(100, width - 115), 30);
    self.closeButton.frame = CGRectMake(width - 88, 11, 76, 32);
    self.webView.frame = CGRectMake(10, 54, MAX(0, width - 20), MAX(0, height - 64));
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"audioSync"]) return;

    CGFloat level = 0.0;
    if ([message.body respondsToSelector:@selector(doubleValue)]) {
        level = (CGFloat)[message.body doubleValue];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [[TweakManager sharedInstance] updateAudioVisualizerLevel:level];
    });
}

- (void)closeGUI {
    [[TweakManager sharedInstance] toggleMainGUI];
}

- (void)dealloc {
    [self.webView.configuration.userContentController
        removeScriptMessageHandlerForName:@"audioSync"];
    [self.webView stopLoading];
}

@end

#pragma mark - Overlay manager

@implementation TweakManager

+ (instancetype)sharedInstance {
    static TweakManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TweakManager alloc] init];
    });
    return instance;
}

- (UIWindow *)activeWindow {
    UIApplication *application = UIApplication.sharedApplication;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) return window;
            }
            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0.0) return window;
            }
        }
        return nil;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return application.keyWindow;
#pragma clang diagnostic pop
}

- (void)setupUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toggleButton || self.mainContainerView) return;

        UIWindow *window = [self activeWindow];
        if (!window) {
            // Window may not exist yet. Retry once the app has had time to create it.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self setupUI];
            });
            return;
        }

        self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.toggleButton.frame = CGRectMake(20, 120, 50, 50);
        self.toggleButton.backgroundColor = UIColor.systemBlueColor;
        [self.toggleButton setTitle:@"YT" forState:UIControlStateNormal];
        [self.toggleButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.toggleButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
        self.toggleButton.layer.cornerRadius = 25.0;
        self.toggleButton.layer.shadowColor = UIColor.blackColor.CGColor;
        self.toggleButton.layer.shadowOpacity = 0.45;
        self.toggleButton.layer.shadowOffset = CGSizeMake(0, 2);
        self.toggleButton.layer.shadowRadius = 4.0;
        [self.toggleButton addTarget:self
                              action:@selector(toggleMainGUI)
                    forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan =
            [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(handleTogglePan:)];
        [self.toggleButton addGestureRecognizer:pan];
        [window addSubview:self.toggleButton];

        CGRect bounds = window.bounds;
        CGFloat guiW = MAX(260.0, CGRectGetWidth(bounds) - 32.0);
        guiW = MIN(guiW, CGRectGetWidth(bounds) - 20.0);
        CGFloat guiH = MAX(300.0, CGRectGetHeight(bounds) - 140.0);
        guiH = MIN(guiH, CGRectGetHeight(bounds) - 80.0);

        self.mainContainerView =
            [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(bounds) - guiW) / 2.0,
                                                     50.0, guiW, guiH)];
        self.mainContainerView.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.mainContainerView.hidden = YES;

        self.mainVC = [[MainGUIViewController alloc] init];
        self.mainVC.view.frame = self.mainContainerView.bounds;
        self.mainVC.view.autoresizingMask =
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.mainContainerView addSubview:self.mainVC.view];
        [window addSubview:self.mainContainerView];

        self.fpsView = [[FPSVisualizerView alloc]
            initWithFrame:CGRectMake(MAX(8.0, CGRectGetWidth(bounds) - 126.0), 190.0, 112.0, 55.0)];
        [window addSubview:self.fpsView];
    });
}

- (void)toggleMainGUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.mainContainerView) return;
        self.mainContainerView.hidden = !self.mainContainerView.hidden;
    });
}

- (void)handleTogglePan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    UIView *parent = view.superview;
    if (!view || !parent) return;

    CGPoint translation = [gesture translationInView:parent];
    CGPoint center = view.center;
    center.x += translation.x;
    center.y += translation.y;

    CGFloat halfW = CGRectGetWidth(view.bounds) / 2.0;
    CGFloat halfH = CGRectGetHeight(view.bounds) / 2.0;
    center.x = MIN(MAX(halfW, center.x), CGRectGetWidth(parent.bounds) - halfW);
    center.y = MIN(MAX(halfH, center.y), CGRectGetHeight(parent.bounds) - halfH);
    view.center = center;

    [gesture setTranslation:CGPointZero inView:parent];
}

- (void)updateAudioVisualizerLevel:(CGFloat)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.fpsView updateBarsWithLevel:level];
    });
}

@end

#pragma mark - Tweak startup

__attribute__((constructor))
static void initTweak(void) {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
            [[TweakManager sharedInstance] setupUI];
        }];
    }
}
