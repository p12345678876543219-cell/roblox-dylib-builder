#import <UIKit/UIKit.h>

// Khai báo biến toàn cục
static UIButton *floatingBtn = nil;
static UIView *menuView = nil;
static UISwitch *aiSwitch = nil;
static UITextField *apiKeyField = nil;
static BOOL isAIControlled = NO;

// Hàm xử lý kéo thả nút nổi trên màn hình
@interface FloatingButtonGesture : NSObject
@end

@implementation FloatingButtonGesture
+ (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:btn.superview];
    
    // Cập nhật vị trí menu đi theo nút
    if (menuView && !menuView.hidden) {
        menuView.center = CGPointMake(btn.center.x, btn.center.y + 60);
    }
}
@end

// Khai báo trước các hàm sự kiện
void toggleMenu(void);
void aiSwitchChanged(UISwitch *sender);
void saveAction(void);
void sendDataToAI(NSString *apiKey, NSString *prompt);

// Hàm gọi API của AI
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
        NSLog(@"[AI Tweak Success] Đã nhận phản hồi từ AI.");
    }];
    [task resume];
}

// Khởi tạo giao diện Menu và Nút nổi
void setupUI() {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) return;
    
    // 1. Tạo Nút Nổi (Floating Button)
    if (!floatingBtn) {
        floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(50, 100, 50, 50);
        floatingBtn.backgroundColor = [UIColor systemBlueColor];
        [floatingBtn setTitle:@"🤖" forState:UIControlStateNormal];
        floatingBtn.layer.cornerRadius = 25;
        floatingBtn.layer.shadowColor = [UIColor blackColor].CGColor;
        floatingBtn.layer.shadowRadius = 4;
        floatingBtn.layer.shadowOpacity = 0.3;
        
        // Thêm sự kiện bấm để ẩn/hiện menu
        [floatingBtn addTarget:nil action:@selector(toggleMenuAction) forControlEvents:UIControlEventTouchUpInside];
        
        // Thêm cử chỉ kéo thả (Drag)
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[FloatingButtonGesture class] action:@selector(handlePan:)];
        [floatingBtn addGestureRecognizer:pan];
        
        [window addSubview:floatingBtn];
    }
    
    // 2. Tạo Menu View
    if (!menuView) {
        menuView = [[UIView alloc] initWithFrame:CGRectMake(50, 160, 260, 200)];
        menuView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.9];
        menuView.layer.cornerRadius = 12;
        menuView.hidden = YES;
        
        // Tiêu đề Menu
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 230, 25)];
        titleLabel.text = @"AI Controller Menu";
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [menuView addSubview:titleLabel];
        
        // Ô nhập API Key
        apiKeyField = [[UITextField alloc] initWithFrame:CGRectMake(15, 45, 230, 35)];
        apiKeyField.placeholder = @"Dán API Key vào đây...";
        apiKeyField.borderStyle = UITextBorderStyleRoundedRect;
        apiKeyField.font = [UIFont systemFontOfSize:13];
        apiKeyField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [menuView addSubview:apiKeyField];
        
        // Nhãn Công tắc AI
        UILabel *switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 95, 160, 30)];
        switchLabel.text = @"Bật AI Điều Khiển";
        switchLabel.textColor = [UIColor whiteColor];
        switchLabel.font = [UIFont systemFontOfSize:14];
        [menuView addSubview:switchLabel];
        
        // Công tắc (Switch)
        aiSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(190, 95, 0, 0)];
        [aiSwitch addTarget:nil action:@selector(aiSwitchChangedAction:) forControlEvents:UIControlEventValueChanged];
        [menuView addSubview:aiSwitch];
        
        // Nút Lưu / Xác nhận
        UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        saveBtn.frame = CGRectMake(15, 145, 230, 35);
        [saveBtn setTitle:@"Xác nhận / Test API" forState:UIControlStateNormal];
        [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        saveBtn.backgroundColor = [UIColor systemGreenColor];
        saveBtn.layer.cornerRadius = 8;
        [saveBtn addTarget:nil action:@selector(saveActionClick) forControlEvents:UIControlEventTouchUpInside];
        [menuView addSubview:saveBtn];
        
        [window addSubview:menuView];
    }
}

// Helper targets cho Button / Switch
@interface AITweakHelper : NSObject
@end
@implementation AITweakHelper
- (void)toggleMenuAction {
    toggleMenu();
}
- (void)aiSwitchChangedAction:(UISwitch *)sender {
    aiSwitchChanged(sender);
}
- (void)saveActionClick {
    saveAction();
}
@end

// Xử lý bật/tắt menu khi bấm nút nổi
void toggleMenu() {
    if (menuView) {
        menuView.hidden = !menuView.hidden;
    }
}

// Xử lý khi bật/tắt công tắc AI
void aiSwitchChanged(UISwitch *sender) {
    isAIControlled = sender.isOn;
    if (isAIControlled) {
        NSLog(@"[AI Tweak] Đã BẬT AI điều khiển ứng dụng.");
        sendDataToAI(apiKeyField.text, @"Trạng thái ứng dụng hiện tại, hãy phân tích và đưa ra hành động.");
    } else {
        NSLog(@"[AI Tweak] Đã TẮT AI điều khiển.");
    }
}

// Xử lý nút lưu API Key
void saveAction() {
    [apiKeyField resignFirstResponder];
    [[NSUserDefaults standardUserDefaults] setObject:apiKeyField.text forKey:@"AITweak_APIKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Đã lưu" message:@"Đã lưu API Key thành công!" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [rootVC presentViewController:alert animated:YES completion:nil];
}

// Bắt sự kiện UIWindow để tự động load UI khi app khởi chạy
@interface UIWindow (AITweak)
@end
@implementation UIWindow (AITweak)
- (void)didAddSubview:(UIView *)subview {
    [super didAddSubview:subview];
    setupUI();
}
@end

// Constructor khởi chạy tweak
__attribute__((constructor)) static void initTweak() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupUI();
        NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"AITweak_APIKey"];
        if (savedKey && apiKeyField) {
            apiKeyField.text = savedKey;
        }
    });
}
