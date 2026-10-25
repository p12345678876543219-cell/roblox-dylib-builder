#substrate headers
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

// Biến toàn cục quản lý tốc độ và giao diện
static float gameSpeed = 1.0f;
static BOOL isSpeedHackEnabled = NO;
static UIWindow *modWindow = nil;
static UIView *mainView = nil;
static UILabel *speedLabel = nil;

// Hàmhook tốc độ game (Tùy chỉnh theo engine game, ví dụ Unity Time.timeScale)
// Nếu là game Unity, bạn có thể hook hàm UnitySetTimeScale hoặc biến tương ứng.
// Dưới đây là khung mẫu hook cơ bản:
/*
float (*old_get_timeScale)(void);
float new_get_timeScale(void) {
    if (isSpeedHackEnabled) {
        return gameSpeed;
    }
    return old_get_timeScale();
}
*/

// Xử lý kéo thả Menu
@interface DraggableButton : UIButton
@end

@implementation DraggableButton {
    CGPoint _startLocation;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    _startLocation = [touch locationInView:self.superview];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self.superview];
    
    CGFloat dx = currentLocation.x - _startLocation.x;
    CGFloat dy = currentLocation.y - _startLocation.y;
    
    CGPoint newCenter = CGPointMake(self.center.x + dx, self.center.y + dy);
    
    // Giới hạn trong màn hình
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    newCenter.x = MAX(30, MIN(screenSize.width - 30, newCenter.x));
    newCenter.y = MAX(30, MIN(screenSize.height - 30, newCenter.y));
    
    self.center = newCenter;
    mainView.center = newCenter;
    
    _startLocation = currentLocation;
}
@end

// Tạo Giao diện GUI
void createModMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (modWindow) return;
        
        UIWindowScene *scene = nil;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if ([s isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        
        if (scene) {
            modWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            modWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        
        modWindow.windowLevel = UIWindowLevelAlert + 999;
        modWindow.backgroundColor = [UIColor clearColor];
        modWindow.hidden = NO;
        
        // Cửa sổ chứa tương tác
        UIViewController *vc = [[UIViewController alloc] init];
        modWindow.rootViewController = vc;
        
        // 1. Nút nổi để mở/đóng Menu (Có thể kéo thả)
        DraggableButton *floatBtn = [DraggableButton buttonWithType:UIButtonTypeCustom];
        floatBtn.frame = CGRectMake(50, 100, 55, 55);
        floatBtn.layer.cornerRadius = 27.5;
        floatBtn.clipsToBounds = YES;
        floatBtn.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        [floatBtn setTitle:@"⚡️" forState:UIControlStateNormal];
        floatBtn.titleLabel.font = [UIFont systemFontOfSize:24];
        [floatBtn addTarget:nil action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:floatBtn];
        
        // 2. Menu chính (Hiệu ứng Kính lỏng - Glassmorphism)
        mainView = [[UIView alloc] initWithFrame:CGRectMake(120, 100, 240, 200)];
        mainView.layer.cornerRadius = 16;
        mainView.clipsToBounds = YES;
        mainView.hidden = YES;
        
        // Hiệu ứng blur kính mờ iOS
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = mainView.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [mainView addSubview:blurView];
        
        // Viền kính sáng nhẹ
        mainView.layer.borderWidth = 1.0;
        mainView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].cgInflater;
        
        // Tiêu đề Menu
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 220, 30)];
        titleLabel.text = @"🚀 Speed Hack Menu";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:15];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        [mainView addSubview:titleLabel];
        
        // Nút Bật/Tắt Speed Hack
        UISwitch *speedSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 50, 0, 0)];
        [speedSwitch addTarget:nil action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [mainView addSubview:speedSwitch];
        
        UILabel *switchText = [[UILabel alloc] initWithFrame:CGRectMake(85, 50, 130, 30)];
        switchText.text = @"Bật Tốc Độ";
        switchText.textColor = [UIColor whiteColor];
        switchText.font = [UIFont systemFontOfSize:14];
        [mainView addSubview:switchText];
        
        // Hiển thị tốc độ
        speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 95, 200, 30)];
        speedLabel.text = [NSString stringWithFormat:@"Tốc độ: %.1fx", gameSpeed];
        speedLabel.textColor = [UIColor cyanColor];
        speedLabel.font = [UIFont boldSystemFontOfSize:14];
        speedLabel.textAlignment = NSTextAlignmentCenter;
        [mainView addSubview:speedLabel];
        
        // Nút Giảm (-)
        UIButton *minusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        minusBtn.frame = CGRectMake(20, 140, 90, 40);
        minusBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        minusBtn.layer.cornerRadius = 10;
        [minusBtn setTitle:@"- 0.5x" forState:UIControlStateNormal];
        [minusBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [minusBtn addTarget:nil action:@selector(decreaseSpeed) forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:minusBtn];
        
        // Nút Tăng (+)
        UIButton *plusBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        plusBtn.frame = CGRectMake(130, 140, 90, 40);
        plusBtn.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        plusBtn.layer.cornerRadius = 10;
        [plusBtn setTitle:@"+ 0.5x" forState:UIControlStateNormal];
        [plusBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [plusBtn addTarget:nil action:@selector(plusSpeed) forControlEvents:UIControlEventTouchUpInside];
        [mainView addSubview:plusBtn];
        
        [vc.view addSubview:mainView];
    }
}

// Các sự kiện tương tác nút bấm
void toggleMenu() {
    mainView.hidden = !mainView.hidden;
}

void switchChanged(UISwitch *sender) {
    isSpeedHackEnabled = sender.on;
}

void decreaseSpeed() {
    if (gameSpeed > 0.5f) {
        gameSpeed -= 0.5f;
        speedLabel.text = [NSString stringWithFormat:@"Tốc độ: %.1fx", gameSpeed];
    }
}

void plusSpeed() {
    if (gameSpeed < 10.0f) {
        gameSpeed += 0.5f;
        speedLabel.text = [NSString stringWithFormat:@"Tốc độ: %.1fx", gameSpeed];
    }
}

// Khởi chạy khi dylib được tiêm vào ứng dụng
__attribute__((constructor)) void entry() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createModMenu();
    });
}
