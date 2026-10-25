
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@interface LGMenu : NSObject
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *toggle;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIButton *stateButton;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) BOOL speedEnabled;
@property (nonatomic, assign) BOOL menuVisible;
@property (nonatomic, assign) CGPoint startCenter;
@property (nonatomic, assign) BOOL dragging;
+ (instancetype)shared;
- (void)start;
@end

@implementation LGMenu

+ (instancetype)shared {
    static LGMenu *obj;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        obj = [[LGMenu alloc] init];
    });
    return obj;
}

- (void)start {
    if (self.toggle.superview != nil) return;

    UIWindow *window = nil;

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;

            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *candidate in ws.windows) {
                if (candidate.isKeyWindow) {
                    window = candidate;
                    break;
                }
            }
            if (window) break;
        }
    }

    if (!window) return;

    self.speed = 1.0;
    self.speedEnabled = YES;
    self.menuVisible = YES;

    // Nút nổi
    self.toggle = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggle.frame = CGRectMake(
        MAX(12.0, window.bounds.size.width - 76.0), 180, 60, 60
    );
    [self.toggle setTitle:@"LG" forState:UIControlStateNormal];
    [self.toggle setTitleColor:UIColor.whiteColor
                      forState:UIControlStateNormal];
    self.toggle.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    self.toggle.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.82];
    self.toggle.layer.cornerRadius = 30;
    self.toggle.layer.borderWidth = 1;
    self.toggle.layer.borderColor =
        [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    self.toggle.layer.shadowColor = UIColor.blackColor.CGColor;
    self.toggle.layer.shadowOpacity = 0.2;
    self.toggle.layer.shadowRadius = 8;

    [self.toggle addTarget:self
                    action:@selector(toggleMenu)
          forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan =
        [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(moveToggle:)];

    pan.cancelsTouchesInView = NO;
    [self.toggle addGestureRecognizer:pan];
    [window addSubview:self.toggle];

    // Menu kính mờ
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(16, 260, 260, 200)];
    self.panel.backgroundColor = UIColor.clearColor;
    self.panel.layer.cornerRadius = 24;
    self.panel.layer.cornerCurve = kCACornerCurveContinuous;
    self.panel.clipsToBounds = YES;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.borderColor =
        [UIColor colorWithWhite:1 alpha:0.3].CGColor;

    UIBlurEffect *blur =
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];

    UIVisualEffectView *glass =
        [[UIVisualEffectView alloc] initWithEffect:blur];

    glass.frame = self.panel.bounds;
    glass.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.panel addSubview:glass];

    UILabel *heading = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 230, 28)];
    heading.text = @"LIQUID GLASS";
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont boldSystemFontOfSize:15];
    [self.panel addSubview:heading];

    self.stateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.stateButton.frame = CGRectMake(15, 45, 230, 36);
    self.stateButton.layer.cornerRadius = 12;
    [self.stateButton setTitleColor:UIColor.whiteColor
                           forState:UIControlStateNormal];
    self.stateButton.titleLabel.font = [UIFont systemFontOfSize:14
                                                         weight:UIFontWeightSemibold];
    [self.stateButton addTarget:self
                         action:@selector(toggleSpeed)
               forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:self.stateButton];

    self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 88, 230, 35)];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.textColor = UIColor.whiteColor;
    self.valueLabel.font =
        [UIFont monospacedDigitSystemFontOfSize:25
                                         weight:UIFontWeightSemibold];
    [self.panel addSubview:self.valueLabel];

    UIButton *minus = [UIButton buttonWithType:UIButtonTypeSystem];
    minus.frame = CGRectMake(15, 137, 105, 45);
    minus.layer.cornerRadius = 13;
    minus.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    [minus setTitle:@"−" forState:UIControlStateNormal];
    [minus setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    minus.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    [minus addTarget:self
              action:@selector(decrease)
    forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:minus];

    UIButton *plus = [UIButton buttonWithType:UIButtonTypeSystem];
    plus.frame = CGRectMake(140, 137, 105, 45);
    plus.layer.cornerRadius = 13;
    plus.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16];
    [plus setTitle:@"+" forState:UIControlStateNormal];
    [plus setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    plus.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    [plus addTarget:self
             action:@selector(increase)
   forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:plus];

    [window addSubview:self.panel];
    [self updateUI];
}

- (void)toggleMenu {
    self.menuVisible = !self.menuVisible;

    [UIView animateWithDuration:0.2 animations:^{
        self.panel.alpha = self.menuVisible ? 1.0 : 0.0;
        self.panel.transform = self.menuVisible
            ? CGAffineTransformIdentity
            : CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        self.panel.hidden = !self.menuVisible;
    }];
}

- (void)moveToggle:(UIPanGestureRecognizer *)gesture {
    UIView *container = self.toggle.superview;
    if (!container) return;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.startCenter = self.toggle.center;
        self.dragging = NO;
    }

    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint delta = [gesture translationInView:container];

        if (fabs(delta.x) > 4 || fabs(delta.y) > 4) {
            self.dragging = YES;
        }

        if (self.dragging) {
            CGPoint center = CGPointMake(
                self.startCenter.x + delta.x,
                self.startCenter.y + delta.y
            );

            CGFloat halfW = CGRectGetWidth(self.toggle.bounds) / 2.0;
            CGFloat halfH = CGRectGetHeight(self.toggle.bounds) / 2.0;

            center.x = MAX(halfW, MIN(container.bounds.size.width - halfW, center.x));
            center.y = MAX(halfH, MIN(container.bounds.size.height - halfH, center.y));

            self.toggle.center = center;
        }
    }

    if (gesture.state == UIGestureRecognizerStateEnded && self.dragging) {
        // Không bật/tắt menu khi người dùng vừa kéo nút.
        [self.toggle removeTarget:self
                           action:@selector(toggleMenu)
                 forControlEvents:UIControlEventTouchUpInside];

        [self.toggle addTarget:self
                        action:@selector(toggleMenu)
              forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)toggleSpeed {
    self.speedEnabled = !self.speedEnabled;
    [self updateUI];
}

- (void)increase {
    if (!self.speedEnabled) return;
    self.speed = MIN(3.0, self.speed + 0.25);
    [self updateUI];
}

- (void)decrease {
    if (!self.speedEnabled) return;
    self.speed = MAX(0.25, self.speed - 0.25);
    [self updateUI];
}

- (void)updateUI {
    self.valueLabel.text = [NSString stringWithFormat:@"%.2f×", self.speed];

    [self.stateButton setTitle:(self.speedEnabled
        ? @"TỐC ĐỘ: BẬT"
        : @"TỐC ĐỘ: TẮT")
                      forState:UIControlStateNormal];

    self.stateButton.backgroundColor = self.speedEnabled
        ? UIColor.systemGreenColor
        : UIColor.systemRedColor;
}

@end

// Khởi chạy khi ứng dụng hoạt động, không dùng +load lồng nhiều block.
static void LGTryStartMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LGMenu shared] start];
    });
}

__attribute__((constructor))
static void LGInitialize(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

        [center addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(NSNotification *notification) {
            LGTryStartMenu();
        }];

        LGTryStartMenu();
    });
}
