//
//  ViewController.m
//  WKWebViewDemo
//
//  Created by zhanggui on 2016/11/25.
//  Copyright © 2016年 zhanggui. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "MJRefresh.h"

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate>

@property (nonatomic,strong)WKWebView *webView;
@property (nonatomic,strong)UIProgressView *progress;
@end

@implementation ViewController
#pragma mark - Life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self p_loadRequest];
    
}
#pragma mark - observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progress.progress = [change[@"new"] floatValue];
    }
}


#pragma mark -
- (IBAction)evalJavaScriptAction:(id)sender {
    //NSString *str = @"alert(1)";
  //  [self.webView evaluateJavaScript:str completionHandler:^(id _Nullable s, NSError * _Nullable error) {
    //    NSLog(@"%@---%@",s,error);
    //}];
    [self.webView stopLoading];
}
#pragma mark - WKWebView NavigationDelegate

//WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"是否允许这个导航");
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
//    Decides whether to allow or cancel a navigation after its response is known.

    NSLog(@"知道返回内容之后，是否允许加载，允许加载");
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"开始加载");
    self.progress.alpha  = 1;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"跳转到其他的服务器");
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"网页由于某些原因加载失败");
    self.progress.alpha  = 0;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"网页开始接收网页内容");
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"网页导航加载完毕");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    self.title = webView.title;
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable ss, NSError * _Nullable error) {
        NSLog(@"----document.title:%@---webView title:%@",ss,webView.title);
    }];
    self.progress.alpha  = 0;
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"加载失败,失败原因:%@",[error description]);
    self.progress.alpha = 0;
}
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"网页加载内容进程终止");
}
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
  //  completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,);
//}
#pragma mark - WKWebView WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSLog(@"创建一个新的webView");
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定1" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webViewDidClose:(WKWebView *)webView {

}


- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    completionHandler(YES);
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    completionHandler(@"oc对象");
}


- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    return YES;
}



- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    NSLog(@"Called when the user performs a pop action on the preview.");
}





#pragma mark - private method
- (void)p_loadRequest {
   // NSURL *url = [[NSURL alloc] initWithString:@"https://www.shuquwangluo.com/loannav/index.html?app=1&uid=1234"];
    NSURL *url = [[NSURL alloc] initWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10];
    [self.webView loadRequest:request];
   
    
    //加载本地网页
    //NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    //NSURL *url = [NSURL fileURLWithPath:urlStr];
    //[self.webView loadFileURL:url allowingReadAccessToURL:url];
    
}
#pragma mark - Lazy load
- (WKWebView *)webView {
    if (!_webView) {
        WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
        _webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 66, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) configuration:webViewConfiguration];
        _webView.allowsBackForwardNavigationGestures = YES;
        _webView.navigationDelegate = self;
        _webView.allowsLinkPreview = YES;
        _webView.UIDelegate = self;
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        [self.view addSubview:_webView];
    }
    return _webView;
}
- (UIProgressView *)progress {
    if (!_progress) {
        _progress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, 2)];
        _progress.backgroundColor = [UIColor lightGrayColor];
        _progress.progressTintColor = [UIColor redColor];
        [self.view addSubview:_progress];
    }
    return _progress;
}

@end
