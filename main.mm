#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>

@interface TweakManager : NSObject
+ (instancetype)sharedInstance;
- (void)setupUI;
@end

// --- 1. Hộp FPS nhỏ gọn, di chuyển được & Hiệu ứng sóng âm ---
@interface FPSVisualizerView : UIView
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) NSMutableArray<UIView *> *barViews;
@end

@implementation FPSVisualizerView {
    CADisplayLink *_displayLink;
    NSTimeInterval _lastTimestamp;
    NSInteger _frameCount;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        self.layer.cornerRadius = 10;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [[UIColor cyanColor] CGColor];
        self.clipsToBounds = YES;
        
        // Nhãn hiển thị FPS
        self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, frame.size.width - 10, 20)];
        self.fpsLabel.textColor = [UIColor greenColor];
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textAlignment = NSTextAlignmentCenter;
        self.fpsLabel.text = @"FPS: 60";
        [self addSubview:self.fpsLabel];
        
        // Tạo các thanh sóng âm (Audio Visualizer bars)
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
        
        // Cử chỉ kéo thả hộp FPS
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        // DisplayLink cập nhật FPS và animation sóng âm liên tục
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
    
    // Hiệu ứng sóng âm nhảy theo nhạc
    for (int i = 0; i < self.barViews.count; i++) {
        UIView *bar = self.barViews[i];
        CGFloat randomHeight = 4 + (arc4random_uniform(15));
        CGRect frame = bar.frame;
        frame.size.height = randomHeight;
        frame.origin.y = 30 + (18 - randomHeight);
        bar.frame = frame;
    }
}
@end

// --- 2. Giao diện chính chứa YouTube (Gần hết màn hình) ---
@interface MainGUIViewController : UIViewController
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
    
    // Tiêu đề GUI
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 220, 30)];
    titleLabel.text = @"YouTube Music HUD";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.view addSubview:titleLabel];
    
    // Nút đóng GUI (Nhạc vẫn chạy ngầm vì WebView chỉ bị ẩn, không bị huỷ)
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 50, 15, 30, 30);
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.closeButton addTarget:self action:@selector(closeGUI) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    // WKWebView chạy YouTube (Hỗ trợ phát nhạc nền)
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    
    CGFloat webY = 60;
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(10, webY, self.view.frame.size.width - 20, self.view.frame.size.height - webY - 10) configuration:config];
    self.webView.layer.cornerRadius = 10;
    self.webView.clipsToBounds = YES;
    
    NSURL *url = [NSURL URLWithString:@"https://www.youtube.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
}

- (void)closeGUI {
    // Ẩn container chứa GUI, nhạc bên trong WebView tiếp tục phát ngầm
    self.view.superview.hidden = YES;
}

@end

// --- 3. Quản lý hiển thị và Nút bật/tắt chính ---
@interface TweakManager ()
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *mainContainerView;
@property (nonatomic, strong) MainGUIViewController *mainVC;
@property (nonatomic, strong) FPSVisualizerView *fpsView;
@end

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
        
        // Nút tròn nổi bật tắt/mở GUI
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
        
        // Cho phép kéo nút bật/tắt đi quanh màn hình
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTogglePan:)];
        [self.toggleButton addGestureRecognizer:pan];
        [keyWindow addSubview:self.toggleButton];
        
        // Main GUI (Gần hết màn hình: Cách mép 20px mỗi bên)
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGFloat guiW = screenRect.size.width - 40;
        CGFloat guiH = screenRect.size.height - 100;
        
        self.mainContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 50, guiW, guiH)];
        self.mainContainerView.hidden = YES; // Mặc định ẩn
        
        self.mainVC = [[MainGUIViewController alloc] init];
        self.mainVC.view.frame = self.mainContainerView.bounds;
        [self.mainContainerView addSubview:self.mainVC.view];
        [keyWindow addSubview:self.mainContainerView];
        
        // Hộp FPS và sóng âm nhỏ gọn, góc phải màn hình
        self.fpsView = [[FPSVisualizerView alloc] initWithFrame:CGRectMake(screenRect.size.width - 130, 120, 110, 55)];
        [keyWindow addSubview:self.fpsView];
    });
}

- (void)toggleMainGUI {
    self.mainContainerView.hidden = !self.mainContainerView.hidden;
}

- (void)handleTogglePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:gesture.view.superview];
    CGPoint center = gesture.view.center;
    gesture.view.center = CGPointMake(center.x + translation.x, center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:gesture.view.superview];
}

@end

// Điểm khởi chạy tự động khi file dylib được nạp vào game
__attribute__((constructor)) static void initTweak() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        [[TweakManager sharedInstance] setupUI];
    }];
}
