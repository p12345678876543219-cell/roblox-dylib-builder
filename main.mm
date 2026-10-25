#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface RobloxNeonMenu : NSObject <UIDocumentPickerDelegate>
+ (instancetype)sharedInstance;
@end

@implementation RobloxNeonMenu {
    UIButton *floatBtn;
    UIView *menuView;
    UIView *tab1View;
    UIView *tab2View;
    WKWebView *webView;
    UILabel *statusLabel;
    UILabel *fileNameLabel;
    UISegmentedControl *segmentedControl;
    UIButton *closeBtn;
    UIButton *pickIpaBtn;
    UIButton *runIpaBtn;
    NSURL *selectedIpaURL;
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

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 220, 25)];
    titleLabel.text = @"DELTA IPA LOADER (MOD)";
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

    NSArray *itemArray = @[@"Trình Duyệt Chrome", @"Quản Lý IPA"];
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

    // Tab 2: IPA Loader & Runner Interface
    tab2View = [[UIView alloc] initWithFrame:contentRect];
    tab2View.hidden = NO;

    // Hiển thị tên file IPA được chọn
    fileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 20, contentW - 20, 40)];
    fileNameLabel.text = @"Chưa chọn file IPA nào";
    fileNameLabel.textColor = [UIColor colorWithRed:0.2 green:1.0 blue:0.4 alpha:1.0];
    fileNameLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13] ?: [UIFont boldSystemFontOfSize:13];
    fileNameLabel.numberOfLines = 2;
    fileNameLabel.textAlignment = NSTextAlignmentCenter;
    fileNameLabel.backgroundColor = [UIColor colorWithRed:0.04 green:0.01 blue:0.07 alpha:1.0];
    fileNameLabel.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    fileNameLabel.layer.borderWidth = 1.0;
    fileNameLabel.layer.cornerRadius = 8.0;
    fileNameLabel.clipsToBounds = YES;
    [tab2View addSubview:fileNameLabel];

    // Nút Chọn File IPA
    pickIpaBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    pickIpaBtn.frame = CGRectMake(10, 80, contentW - 20, 44);
    pickIpaBtn.backgroundColor = [UIColor colorWithRed:0.35 green:0.08 blue:0.6 alpha:1.0];
    [pickIpaBtn setTitle:@"📂 Chọn File IPA từ thiết bị" forState:UIControlStateNormal];
    [pickIpaBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    pickIpaBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    pickIpaBtn.layer.cornerRadius = 8;
    [pickIpaBtn addTarget:self action:@selector(selectIPAFile) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:pickIpaBtn];

    // Nút Chạy/Xử lý App IPA
    runIpaBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    runIpaBtn.frame = CGRectMake(10, 135, contentW - 20, 44);
    runIpaBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.4 blue:0.2 alpha:1.0];
    [runIpaBtn setTitle:@"🚀 Chạy / Cài Đặt Ứng Dụng IPA" forState:UIControlStateNormal];
    [runIpaBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    runIpaBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    runIpaBtn.layer.cornerRadius = 8;
    [runIpaBtn addTarget:self action:@selector(runOrProcessIPA) forControlEvents:UIControlEventTouchUpInside];
    [tab2View addSubview:runIpaBtn];

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

- (void)selectIPAFile {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.item", @"public.data"] inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    [keyWindow.rootViewController presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        selectedIpaURL = urls.firstObject;
        [selectedIpaURL startAccessingSecurityScopedResource];
        
        NSString *fileName = [selectedIpaURL lastPathComponent];
        fileNameLabel.text = [NSString stringWithFormat:@"Đã chọn: %@", fileName];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thành công" 
                                                                        message:[NSString stringWithFormat:@"Đã nạp file: %@", fileName] 
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *keyWindow = [self getCurrentKeyWindow];
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)runOrProcessIPA {
    if (!selectedIpaURL) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thông báo" 
                                                                        message:@"Vui lòng chọn một file IPA trước khi chạy!" 
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        UIWindow *keyWindow = [self getCurrentKeyWindow];
        [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Xử lý nạp/chạy file IPA trong giới hạn sandboxing của iOS
    NSString *msg = [NSString stringWithFormat:@"Đang xử lý gói IPA: %@\n(Lưu ý: iOS không cho phép ứng dụng chạy trực tiếp file IPA độc lập bên trong tiến trình game khác do chính sách Sandbox).", [selectedIpaURL lastPathComponent]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPA Loader" 
                                                                    message:msg 
                                                             preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIWindow *keyWindow = [self getCurrentKeyWindow];
    [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
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
    
    fileNameLabel.frame = CGRectMake(10, 20, contentW - 20, 40);
    pickIpaBtn.frame = CGRectMake(10, 80, contentW - 20, 44);
    runIpaBtn.frame = CGRectMake(10, 135, contentW - 20, 44);

    closeBtn.frame = CGRectMake(w - 38, 8, 28, 28);
    segmentedControl.frame = CGRectMake(15, 40, w - 30, 32);
}

@end

__attribute__((constructor)) static void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [RobloxNeonMenu sharedInstance];
    });
}
