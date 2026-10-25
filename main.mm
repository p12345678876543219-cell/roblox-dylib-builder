- (void)setupUI {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;
        
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
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleTogglePan:)];
        [self.toggleButton addGestureRecognizer:pan];
        [keyWindow addSubview:self.toggleButton];
        
        // Thay thế [UIScreen mainScreen] bằng keyWindow.bounds để tương thích hoàn toàn với Xcode mới và tránh lỗi cú pháp
        CGRect screenRect = keyWindow.bounds;
        CGFloat guiW = screenRect.size.width - 40;
        CGFloat guiH = screenRect.size.height - 100;
        
        self.mainContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 50, guiW, guiH)];
        self.mainContainerView.hidden = YES;
        
        MainGUIViewController *mainVC = [[MainGUIViewController alloc] init];
        self.mainVC = mainVC;
        mainVC.view.frame = self.mainContainerView.bounds;
        [self.mainContainerView addSubview:mainVC.view];
        [keyWindow addSubview:self.mainContainerView];
        
        self.fpsView = [[FPSVisualizerView alloc] initWithFrame:CGRectMake(screenRect.size.width - 130, 120, 110, 55)];
        [keyWindow addSubview:self.fpsView];
    });
}
