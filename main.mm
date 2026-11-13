#import <UIKit/UIKit.h>

static UIButton *floatingBtn = nil;
static UIView *menuView = nil;
static UISwitch *aiSwitch = nil;
static UITextField *apiKeyField = nil;
static BOOL isAIControlled = NO;

// Khai báo trước các hàm
void setupUI(void);
void toggleMenu(void);
void sendDataToAI(NSString *apiKey, NSString *prompt);

// Class xử lý cử chỉ kéo thả (Drag) nút nổi
@interface AITouchHandler : NSObject
+atomy void handlePan:(UIPanGestureRecognizer *)gesture;
+ (void)onButtonClicked;
@end

@implementation AITouchHandler
+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:btn.superview];
    
    // Ghim menu đi theo nút nổi
    if (menuView) {
        menuView.center = CGPointMake(btn.center.x, btn.center.y + 110);
    }
}

+ (void)onButtonClicked {
    if (menuView) {
        menuView.hidden = !menuView.hidden;
        // Đưa menu lên lớp trên cùng để không bị che khuất bởi UI của game/app
        [menuView.superview bringSubviewToFront:menuView];
        [menuView.superview bringSubviewToFront:floatingBtn];
    }
}

+ (void)onSwitchChanged:(UISwitch *)sender {
    isAIControlled = sender.isOn;
    if (isAIControlled) {
        NSLog(@"[AI Tweak] Đã BẬT AI điều khiển.");
        sendDataToAI(apiKeyField.text, @"Phân tích trạng thái màn hình hiện tại và đưa ra thao tác.");
    } else {
        NSLog(@"[AI Tweak] Đã TẮT AI điều khiển.");
    }
}

+ (void)onSaveClicked {
    [apiKeyField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:apiKeyField.text forKey:@"AITweak_APIKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thành công" message:@"Đã lưu API Key!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [rootVC presentViewController:alert animated:YES completion:nil];
}
@end

// Gửi request API
void sendDataToAI(NSString *apiKey, NSString *prompt) {
    if (apiKey.length == 0) {
        NSLog(@"[AI Tweak] Chưa nhập API Key!");
        return;
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.openai.com/v1/chat/completions"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", apiKey] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = @{
        @"model": @"gpt-4o-mini",
        @"messages": @[@{@"role": @"user", @"content": prompt}]
    };
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
    [request setHTTPBody:jsonData];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"[AI Tweak Error] %@", error.localizedDescription);
            return;
        }
        NSLog(@"[AI Tweak Success] Đã gọi API thành công.");
    }];
    [task resume];
}

// Khởi tạo giao diện
void setupUI() {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    // Nếu đã tạo rồi thì không tạo đè nữa
    if (floatingBtn && menuView) return;
    
    // 1. Tạo Nút Nổi
    if (!floatingBtn) {
        floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(40, 100, 50, 50);
        floatingBtn.backgroundColor = [UIColor systemBlueColor];
        [floatingBtn setTitle:@"🤖" forState:UIControlStateNormal];
        floatingBtn.layer.cornerRadius = 25;
        floatingBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        floatingBtn.layer.shadowRadius = 4;
        floatingBtn.layer.shadowOpacity = 0.5;
        
        [floatingBtn addTarget:[AITouchHandler class] action:@selector(onButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[AITouchHandler class] action:@selector(handlePan:)];
        [floatingBtn addGestureRecognizer:pan];
        
        [window addSubview:floatingBtn];
    }
    
    // 2. Tạo Menu View
    if (!menuView) {
        menuView = [[UIView alloc] initWithFrame:CGRectMake(40, 160, 260, 195)];
        menuView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
        menuView.layer.cornerRadius = 14;
        menuView.layer.borderWidth = 1;
        menuView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        menuView.hidden = YES; // Mặc định ẩn, bấm nút nổi mới hiện
        
        // Tiêu đề
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 230, 22)];
        titleLabel.text = @"🤖 AI Controller Menu";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [menuView addSubview:titleLabel];
        
        // Ô nhập API Key
        apiKeyField = [[UITextField alloc] initWithFrame:CGRectMake(15, 42, 230, 35)];
        apiKeyField.placeholder = @"Dán API Key vào đây...";
        apiKeyField.borderStyle = UITextBorderStyleRoundedRect;
        apiKeyField.font = [UIFont systemFontOfSize:12];
        apiKeyField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [menuView addSubview:apiKeyField];
        
        // Nhãn switch
        UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 90, 160, 30)];
        switchLabel.text = @"Bật AI Điều Khiển";
        switchLabel.textColor = [UIColor whiteColor];
        switchLabel.font = [UIFont systemFontOfSize:13];
        [menuView addSubview:switchLabel];
        
        // Switch bật tắt AI
        aiSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(190, 90, 0, 0)];
        [aiSwitch addTarget:[AITouchHandler class] action:@selector(onSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        [menuView addSubview:aiSwitch];
        
        // Nút lưu
        UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        saveBtn.frame = CGRectMake(15, 138, 230, 36);
        [saveBtn setTitle:@"Lưu API Key" forState:UIControlStateNormal];
        [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        saveBtn.backgroundColor = [UIColor systemGreenColor];
        saveBtn.layer.cornerRadius = 8;
        [saveBtn addTarget:[AITouchHandler class] action:@selector(onSaveClicked) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:saveBtn];
        
        [window addSubview:menuView];
    }
}

// Bắt sự kiện Window để load menu đè lên app/game
@interface UIWindow (AIHook)
@end
@implementation UIWindow (AIHook)
- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    setupUI();
}
@end

// Constructor khởi chạy
__attribute__((constructor)) static void initAITweak() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupUI();
        NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"AITweak_APIKey"];
        if (savedKey && apiKeyField) {
            apiKeyField.text = savedKey;
        }
    });
}
