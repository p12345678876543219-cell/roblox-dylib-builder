
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface LGMenu : NSObject
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *toggle;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIButton *enableButton;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) BOOL speedEnabled;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) CGPoint dragCenter;
@property (nonatomic, assign) CGPoint lastCenter;
@end

@implementation LGMenu

+ (instancetype)shared {
    static LGMenu *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LGMenu alloc] init];
    });
    return instance;
}

- (void)start {
    if (self.toggle.superview) return;

    UIWindow *window = nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            if (ws.activationState != UISceneActivationStateForegroundActive)
                continue;

            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow) {
                    window = w;
                    break;
                }
            }
            if (window) break;
        }
    }

    if (!window) {
        for (UIWindow *w in UIApplication.sharedApplication.windows) {
            if (!w.hidden && w.alpha > 0) {
                window = w;
                if (w.isKeyWindow) break;
            }
        }
    }

    if (!window) return;

    self.speed = 1.0;
    self.speedEnabled = YES;
    self.visible = YES;

    // Nút nổi
    self.toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggle.frame = CGRectMake(
        MAX(12, window.bounds.size.width - 76), 180, 60, 60
    );
    [self.toggle setTitle:@"LG" forState:UIControlStateNormal];
    [self.toggle setTitleColor:UIColor.whiteColor
                      forState:UIControlStateNormal];
    self.toggle.titleLabel.font =
        [UIFont boldSystemFontOfSize:19];
    self.toggle.backgroundColor =
        [UIColor colorWithWhite:0.12 alpha:0.78];
    self.toggle.layer.cornerRadius = 30;
    self.toggle.layer.borderWidth = 1;
    self.toggle.layer.borderColor =
        [UIColor colorWithWhite:1 alpha:0.45].CGColor;
    self.toggle.layer.shadowColor = UIColor.blackColor.CGColor;
    self.toggle.layer.shadowOpacity = 0.2;
    self.toggle.layer.shadowRadius = 10;

    [self.toggle addTarget:self
                    action:@selector(togglePanel)
          forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(drag:)];

    [self.toggle addGestureRecognizer:pan];
    [window addSubview:self.toggle];

    // Bảng Liquid Glass
    self.panel = [[UIView alloc]
        initWithFrame:CGRectMake(16, 260, 260, 205)];

    self.panel.backgroundColor = UIColor.clearColor;
    self.panel.layer.cornerRadius = 24;
    self.panel.layer.cornerCurve = kCACornerCurveContinuous;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.borderColor =
        [UIColor colorWithWhite:1 alpha:0.3].CGColor;
    self.panel.clipsToBounds = YES;

    UIBlurEffect *blur =
        [UIBlurEffect effectWithStyle:
            UIBlurEffectStyleSystemThinMaterialDark];

    UIVisualEffectView *glass =
        [[UIVisualEffectView alloc] initWithEffect:blur];

    glass.frame = self.panel.bounds;
    glass.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.panel addSubview:glass];

    UILabel *title = [[UILabel alloc]
        initWithFrame:CGRectMake(15, 10, 230, 28)];

    title.text = @"LIQUID GLASS";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:15];
    [self.panel addSubview:title];

    // Bật / tắt điều chỉnh tốc độ
    self.enableButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.enableButton.frame = CGRectMake(15, 45, 230, 36);
    self.enableButton.layer.cornerRadius = 12;
    self.enableButton.titleLabel.font =
        [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

    [self.enableButton setTitleColor:UIColor.whiteColor
                            forState:UIControlStateNormal];

    [self.enableButton addTarget:self
                          action:@selector(toggleSpeed)
                forControlEvents:UIControlEventTouchUpInside];

    [self.panel addSubview:self.enableButton];

    // Giá trị tốc độ
    self.speedLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(15, 88, 230, 35)];

    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.textColor = UIColor.whiteColor;
    self.speedLabel.font =
        [UIFont monospacedDigitSystemFontOfSize:25
                                         weight:UIFontWeightSemibold];

    [self.panel addSubview:self.speedLabel];

    // Nút trừ
    UIButton *minus = [UIButton buttonWithType:UIButtonTypeSystem];
    minus.frame = CGRectMake(15, 137, 105, 48);
    minus.layer.cornerRadius = 14;
    minus.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    [minus setTitle:@"−" forState:UIControlStateNormal];
    [minus setTitleColor:UIColor.whiteColor
                forState:UIControlStateNormal];
    minus.titleLabel.font = [UIFont boldSystemFontOfSize:27];

    [minus addTarget:self
              action:@selector(decrease)
    forControlEvents:UIControlEventTouchUpInside];

    [self.panel addSubview:minus];

    // Nút cộng
    UIButton *plus = [UIButton buttonWithType:UIButtonTypeSystem];
    plus.frame = CGRectMake(140, 137, 105, 48);
    plus.layer.cornerRadius = 14;
    plus.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    [plus setTitle:@"+" forState:UIControlStateNormal];
    [plus setTitleColor:UIColor.whiteColor
               forState:UIControlStateNormal];
    plus.titleLabel.font = [UIFont boldSystemFontOfSize:27];

    [plus addTarget:self
             action:@selector(increase)
   forControlEvents:UIControlEventTouchUpInside];

    [self.panel addSubview:plus];

    [window addSubview:self.panel];
    [self refresh];
}

- (void)togglePanel {
    self.visible = !self.visible;

    [UIView animateWithDuration:0.2 animations:^{
        self.panel.alpha = self.visible ? 1 : 0;
        self.panel.transform = self.visible
            ? CGAffineTransformIdentity
            : CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        self.panel.hidden = !self.visible;
    }];
}

- (void)drag:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCenter = self.toggle.center;
    }

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint delta = [gesture translationInView:self.toggle.superview];

        CGPoint center = CGPointMake(
            self.lastCenter.x + delta.x,
            self.lastCenter.y + delta.y
        );

        UIView *container = self.toggle.superview;
        CGFloat halfW = self.toggle.bounds.size.width / 2;
        CGFloat halfH = self.toggle.bounds.size.height / 2;

        center.x = MAX(halfW, MIN(container.bounds.size.width - halfW,
                                  center.x));
        center.y = MAX(halfH, MIN(container.bounds.size.height - halfH,
                                  center.y));

        self.toggle.center = center;
    }
}

- (void)toggleSpeed {
    self.speedEnabled = !self.speedEnabled;
    [self refresh];
}

- (void)increase {
    if (!self.speedEnabled) return;
    self.speed = MIN(3.0, self.speed + 0.25);
    [self refresh];
}

- (void)decrease {
    if (!self.speedEnabled) return;
    self.speed = MAX(0.25, self.speed - 0.25);
    [self refresh];
}

- (void)refresh {
    self.speedLabel.text =
        [NSString stringWithFormat:@"%.2f×", self.speed];

    [self.enableButton
        setTitle:(self.speedEnabled
            ? @"TỐC ĐỘ: BẬT"
            : @"TỐC ĐỘ: TẮT")
        forState:UIControlStateNormal];

    self.enableButton.backgroundColor = self.speedEnabled
        ? UIColor.systemGreenColor
        : UIColor.systemRedColor;
}

@end

// Khởi tạo khi ứng dụng đã hoạt động.
@interface LGMenuLoader : NSObject
@end

@implementation LGMenuLoader

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                              (int64_t)(0.5 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [[LGMenu shared] start];
                });
        });

        if (UIApplication.sharedApplication.applicationState
                == UIApplicationStateActive) {
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW,
                              (int64_t)(0.5 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [[LGMenu shared] start];
                });
        }
    });
}

@end
