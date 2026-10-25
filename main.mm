#import <UIKit/UIKit.h>
#import <substrate.h>

// Quản lý toàn bộ giao diện Mod Menu
@interface ModMenuController : NSObject
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UILabel *speedValLabel;
@property (nonatomic, assign) float gameSpeed;
@property (nonatomic, assign) BOOL speedEnabled;
+ (instancetype)sharedInstance;
- (void)setupUI;
@end

@implementation ModMenuController

+ (instancetype)sharedInstance {
    static ModMenuController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ModMenuController alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.gameSpeed = 1.0f;
        self.speedEnabled = NO;
    }
    return self;
}

- (void)setupUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.window) return;

        // 1. Tạo UIWindow riêng biệt đè lên toàn bộ game
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.windowLevel = UIWindowLevelAlert + 999;
        self.window.backgroundColor = [UIColor clearColor];
        self.window.hidden = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        vc.view.backgroundColor = [UIColor clearColor];
        self.window.rootViewController = vc;

        // 2. Nút nổi (Floating Button) - Có thể kéo thả trên màn hình
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(40, 120, 55, 55);
        self.floatingBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
        [self.floatingBtn setTitle:@"MOD" forState:UIControlStateNormal];
        [self.floatingBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        self.floatingBtn.layer.cornerRadius = 27.5f;
        self.floatingBtn.layer.borderWidth = 2.0f;
        self.floatingBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [self.floatingBtn addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *panFloat = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panFloatingButton:)];
        [self.floatingBtn addGestureRecognizer:panFloat];
        [vc.view addSubview:self.floatingBtn];

        // 3. Menu chính (Bảng điều khiển) - Có thể kéo thả
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(100, 180, 260, 230)];
        self.menuView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.15 alpha:0.95];
        self.menuView.layer.cornerRadius = 14.0f;
        self.menuView.layer.borderWidth = 1.5f;
        self.menuView.layer.borderColor = [UIColor systemCyanColor].CGColor;
        self.menuView.hidden = YES; // Mặc định ẩn khi khởi động game

        UIPanGestureRecognizer *panMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMenuAction:)];
        [self.menuView addGestureRecognizer:panMenu];

        // Tiêu đề Menu
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 12, 240, 25)];
        titleLabel.text = @"Subway Surfers Speed Hack";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:titleLabel];

        // Switch bật/tắt Speed Game
        UISwitch *speedSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 55, 0, 0)];
        [speedSwitch addTarget:self action:@selector(speedSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:speedSwitch];

        UILabel *speedText = [[UILabel alloc] initWithFrame:CGRectMake(90, 55, 150, 30)];
        speedText.text = @"Bật Speed Game";
        speedText.textColor = [UIColor whiteColor];
        speedText.font = [UIFont systemFontOfSize:14];
        [self.menuView addSubview:speedText];

        // Nút Giảm Tốc Độ (-)
        UIButton *minusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        minusBtn.frame = CGRectMake(20, 110, 50, 40];
        [minusBtn setTitle:@"-" forState:UIControlStateNormal];
        minusBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        [minusBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        minusBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.28 alpha:1.0];
        minusBtn.layer.cornerRadius = 8;
        [minusBtn addTarget:self action:@selector(decreaseSpeed) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:minusBtn];

        // Hiển thị giá trị tốc độ hiện tại
        self.speedValLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 110, 100, 40)];
        self.speedValLabel.text = @"1.0x";
        self.speedValLabel.textColor = [UIColor yellowColor];
        self.speedValLabel.font = [UIFont boldSystemFontOfSize:16];
        self.speedValLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:self.speedValLabel];

        // Nút Tăng Tốc Độ (+)
        UIButton *plusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        plusBtn.frame = CGRectMake(190, 110, 50, 40];
        [plusBtn setTitle:@"+" forState:UIControlStateNormal];
        plusBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        [plusBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        plusBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.25 blue:0.28 alpha:1.0];
        plusBtn.layer.cornerRadius = 8;
        [plusBtn addTarget:self action:@selector(increaseSpeed) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:plusBtn];

        // Nút Đóng / Ẩn Menu
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(20, 175, 220, 38];
        [closeBtn setTitle:@"Ẩn Menu" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        closeBtn.backgroundColor = [UIColor colorWithRed:0.25 green:0.15 blue:0.15 alpha:1.0];
        closeBtn.layer.cornerRadius = 8;
        [closeBtn addTarget:self action:@selector(toggleMenuVisibility) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:closeBtn];

        [vc.view addSubview:self.menuView];
    });
}

// Hàm ẩn/hiện bảng Menu chính
- (void)toggleMenuVisibility {
    self.menuView.hidden = !self.menuView.hidden;
}

// Xử lý kéo thả nút nổi
- (void)panFloatingButton:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.window];
    self.floatingBtn.center = CGPointMake(self.floatingBtn.center.x + translation.x, self.floatingBtn.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.window];
}

// Xử lý kéo thả bảng Menu
- (void)panMenuAction:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.window];
    self.menuView.center = CGPointMake(self.menuView.center.x + translation.x, self.menuView.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.window];
}

// Trạng thái bật/tắt Speed Hack
- (void)speedSwitchChanged:(UISwitch *)sender {
    self.speedEnabled = sender.isOn;
}

// Giảm tốc độ (-0.2x)
- (void)decreaseSpeed {
    if (self.gameSpeed > 0.2f) {
        self.gameSpeed -= 0.2f;
        self.speedValLabel.text = [NSString stringWithFormat:@"%.1fx", self.gameSpeed];
    }
}

// Tăng tốc độ (+0.2x)
- (void)increaseSpeed {
    if (self.gameSpeed < 10.0f) {
        self.gameSpeed += 0.2f;
        self.speedValLabel.text = [NSString stringWithFormat:@"%.1fx", self.gameSpeed];
    }
}

@end

// ==========================================
// SPEED HACK HOOK (Dành cho game Unity như Subway Surfers)
// ==========================================
typedef float (*Time_get_timeScale_t)(void);
typedef void (*Time_set_timeScale_t)(float);

static Time_set_timeScale_t orig_Time_set_timeScale = NULL;

void hooked_Time_set_timeScale(float value) {
    ModMenuController *menu = [ModMenuController sharedInstance];
    if (menu.speedEnabled) {
        orig_Time_set_timeScale(menu.gameSpeed);
    } else {
        orig_Time_set_timeScale(value);
    }
}

// Khởi chạy Tweak khi game load
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ModMenuController sharedInstance] setupUI];
    });

    void *timeScaleSymbol = MSFindSymbol(NULL, "_UnitySetTimeScale");
    if (timeScaleSymbol) {
        MSHookFunction(timeScaleSymbol, (void *)&hooked_Time_set_timeScale, (void **)&orig_Time_set_timeScale);
    }
}
