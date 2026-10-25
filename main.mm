
#import <UIKit/UIKit.h>

@interface ViewController ()
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, strong) UIView *menu;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, assign) BOOL speedEnabled;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.speed = 1.0;
    self.speedEnabled = YES;
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    // Nút nổi
    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.frame = CGRectMake(self.view.bounds.size.width - 78, 150, 60, 60);
    self.toggleButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.toggleButton setTitle:@"LG" forState:UIControlStateNormal];
    self.toggleButton.titleLabel.font = [UIFont boldSystemFontOfSize:19];
    [self.toggleButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.toggleButton.layer.cornerRadius = 30;
    self.toggleButton.layer.borderWidth = 1;
    self.toggleButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.5].CGColor;
    [self.toggleButton addTarget:self action:@selector(toggleMenu)
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];

    UIPanGestureRecognizer *pan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragButton:)];
    [self.toggleButton addGestureRecognizer:pan];

    // Menu kính mờ
    self.menu = [[UIView alloc] initWithFrame:CGRectMake(20, 230, 260, 190)];
    self.menu.hidden = NO;
    self.menu.layer.cornerRadius = 24;
    self.menu.clipsToBounds = YES;
    self.menu.layer.borderWidth = 1;
    self.menu.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;

    UIBlurEffect *blur =
    [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *glass =
    [[UIVisualEffectView alloc] initWithEffect:blur];
    glass.frame = self.menu.bounds;
    glass.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                             UIViewAutoresizingFlexibleHeight;
    [self.menu addSubview:glass];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 230, 28)];
    title.text = @"LIQUID GLASS";
    title.font = [UIFont boldSystemFontOfSize:15];
    title.textColor = UIColor.labelColor;
    [self.menu addSubview:title];

    UIButton *enable = [UIButton buttonWithType:UIButtonTypeSystem];
    enable.frame = CGRectMake(15, 45, 230, 35);
    enable.tag = 10;
    enable.layer.cornerRadius = 12;
    enable.backgroundColor = UIColor.systemGreenColor;
    [enable setTitle:@"TỐC ĐỘ: BẬT" forState:UIControlStateNormal];
    [enable setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [enable addTarget:self action:@selector(toggleSpeed)
     forControlEvents:UIControlEventTouchUpInside];
    [self.menu addSubview:enable];

    self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 85, 230, 35)];
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.font = [UIFont boldSystemFontOfSize:25];
    self.speedLabel.textColor = UIColor.labelColor;
    [self.menu addSubview:self.speedLabel];

    UIButton *minus = [UIButton buttonWithType:UIButtonTypeSystem];
    minus.frame = CGRectMake(15, 130, 105, 45);
    minus.layer.cornerRadius = 13;
    minus.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    [minus setTitle:@"−" forState:UIControlStateNormal];
    minus.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    [minus addTarget:self action:@selector(decreaseSpeed)
     forControlEvents:UIControlEventTouchUpInside];
    [self.menu addSubview:minus];

    UIButton *plus = [UIButton buttonWithType:UIButtonTypeSystem];
    plus.frame = CGRectMake(140, 130, 105, 45);
    plus.layer.cornerRadius = 13;
    plus.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.2];
    [plus setTitle:@"+" forState:UIControlStateNormal];
    plus.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    [plus addTarget:self action:@selector(increaseSpeed)
    forControlEvents:UIControlEventTouchUpInside];
    [self.menu addSubview:plus];

    [self.view addSubview:self.menu];
    [self updateSpeed];
}

- (void)toggleMenu {
    self.menu.hidden = !self.menu.hidden;
}

- (void)dragButton:(UIPanGestureRecognizer *)gesture {
    CGPoint delta = [gesture translationInView:self.view];
    CGPoint center = self.toggleButton.center;
    center.x += delta.x;
    center.y += delta.y;

    CGFloat halfW = self.toggleButton.bounds.size.width / 2;
    CGFloat halfH = self.toggleButton.bounds.size.height / 2;
    center.x = MAX(halfW, MIN(self.view.bounds.size.width - halfW, center.x));
    center.y = MAX(halfH, MIN(self.view.bounds.size.height - halfH, center.y));

    self.toggleButton.center = center;
    [gesture setTranslation:CGPointZero inView:self.view];
}

- (void)toggleSpeed {
    self.speedEnabled = !self.speedEnabled;
    [self updateSpeed];
}

- (void)increaseSpeed {
    if (!self.speedEnabled) return;
    self.speed = MIN(3.0, self.speed + 0.25);
    [self updateSpeed];
}

- (void)decreaseSpeed {
    if (!self.speedEnabled) return;
    self.speed = MAX(0.25, self.speed - 0.25);
    [self updateSpeed];
}

- (void)updateSpeed {
    self.speedLabel.text =
        [NSString stringWithFormat:@"%.2f×", self.speed];

    UIButton *button = [self.menu viewWithTag:10];
    [button setTitle:(self.speedEnabled ? @"TỐC ĐỘ: BẬT" : @"TỐC ĐỘ: TẮT")
            forState:UIControlStateNormal];
    button.backgroundColor = self.speedEnabled
        ? UIColor.systemGreenColor : UIColor.systemRedColor;

    // Hệ số self.speed cần được tích hợp vào logic của ứng dụng.
    // Nó không tự thay đổi tốc độ của ứng dụng hoặc game khác.
}

@end
