一.前言

上一篇[文章](http://www.cnblogs.com/zhanggui/p/6109417.html)已经对WKWebView做了一个简单的介绍，主要对它的一些方法和属性做了一个简单的介绍，今天看一下WKWebView的两个协议：WKNavigationDelegate 和 WKUIDelegate。

二.WKNavigationDelegate

根据字面意思，它的作用是用于导航（navigation）的代理。其实里面定义了n多个方法，用于处理网页接受、加载和导航请求等自定义的行为。直接拿下面的例子来看：

```
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
//    NSLog(@"receive");
//}
```

首先看一下（WKN1）：

```
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"是否允许这个导航");
    decisionHandler(WKNavigationActionPolicyAllow);
}
```

这个方法是加载网页第一个执行的方法，因为它要确定是否允许或者取消加载这个导航。这里有一个枚举WKNavigationActionPolicy，其结构如下：

```
typedef NS_ENUM(NSInteger, WKNavigationActionPolicy) {
    WKNavigationActionPolicyCancel,
    WKNavigationActionPolicyAllow,
} API_AVAILABLE(macosx(10.10), ios(8.0));
```

这里的两个枚举确定了这个网页是否加载，我们只需要在decisionHandler回调里面传入相应的枚举值即可。这里可以用来处理自己不允许加载的网页，比如你的app里面的网页很多，但是domain只有两个，如果你只想加载这两个domain里面的网页，其他的domain不加载，那么可以在这里进行处理。（可以用来屏蔽移动或联通运营商推送的网页，让其不在app中展示）

这里还有一个WKNavigationAction。它是一个导航动作， 包含了点击之后的导航动作，我们做过滤的时候可以通过该动作决定是否允许加载。它有两个关键的FrameInfo:

```
sourceFrame
targetFrame
```

他们都是WKFrameInfo的实例。该类包含了网页加载的frame的信息。该类有一个重要的属性：mainFrame。它是一个Bool值，用于标识该frame是不是当前网页的主frame或者是子frame。举个例子：

当我们第一次打开百度的时候，navigationAction是这样的：

```
<WKNavigationAction: 0x100410fa0; navigationType = -1; syntheticClickType = 0;
 request = <NSMutableURLRequest: 0x170019a10> { URL: https://www.baidu.com/ }; 
sourceFrame = (null); targetFrame = <WKFrameInfo: 0x100401200; isMainFrame = YES; request = (null)>>
```

它的request url是https://www.baidu.com/。它的sourceFrame是nil，也就是请求导航的frame是空的。它的targetFrame是：

```
<WKFrameInfo: 0x100401200; isMainFrame = YES; request = (null)>
```

这里是在当前的frame打开，也就是目的的frame。当我点击新闻那个链接的时候，其navigationAction是这样的：

```
<WKNavigationAction: 0x1004120b0; navigationType = -1; syntheticClickType = 0; request = <NSMutableURLRequest: 0x17001af30> 
{ URL: http://m.news.baidu.com/news?fr=mohome&ssid=0&from=844b&uid=&pu=sz%401320_2001%2Cta%40iphone_1_10.2_3_602&bd_page_type=1 
}; sourceFrame = (null); targetFrame = <WKFrameInfo: 0x100414ff0; isMainFrame = YES; request = <NSMutableURLRequest: 0x17001b080> 
{ URL: https://www.baidu.com/ }>>
```

可以看到，此时的导航动作是要请求的

```
http://m.news.baidu.com/news?fr=mohome&ssid=0&from=844b&uid=&pu=sz%401320_2001%2Cta%40iphone_1_10.2_3_602&bd_page_type=1
```

也就是网页版百度新闻的链接。此时它的sourceFrame是nil，它的targetFrame是：

```
<WKFrameInfo: 0x100414ff0; isMainFrame = YES; request = <NSMutableURLRequest: 0x17001b080> { URL: https://www.baidu.com/ }>
```

它的目标frame的request是baidu。其中的isMainFrame属性是YES，说明是主的frame，所以还是在当前的网页中打开一个新链接。

此时我们也许会遇到另外一种情况，就是sourceFrame不为空，但是targetFrame为空，这里如果targetFrame为空，那么这个就是新建一个window 导航。用我们自己的话来说就是重新打开了一个tab页面。

![img](http://images2015.cnblogs.com/blog/527522/201703/527522-20170327131351592-361125598.png)

就类似这样，我点击了PC版的网页链接，然后新开了一个tab，这样的话sourceFrame就是当前的百度，而targetFrame就是空的。此时（我用这个[网页](https://www.shuquwangluo.com/loannav/index.html?app=1&uid=1234)测试）你会发现这个代理方法不执行了，好尴尬。。。。处理都不知道怎么处理了。由于新打开了tab，也就意味着我们的请求不在当前的网页加载了，那么也无法调用到这个代理方法了。因此我们需要重新配置这个新打开的网页，这里就会调用：

```
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration 
forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;
```

这个代理方法是WKUIDelegate的代理方法，可在下面查看。

接着就是开始加载（WKN2）：

```
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
```

这个方法比较好理解，就是当网页内容开始加载到web view的时候调用，这里的navigation没有其他特殊含义，看一下WKNavigation这个类可以知道，他就是NSObject的一个子类，而且里面没有任何新增的其他方法或者属性。我想仅仅是为了名字上能够好理解才这样写的吧。

再接着就是（WKN3）：

```
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse 
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
```

这个代理方法了。我们知道了网页是否允许加载，那么一旦不允许，那么这个加载过程就已经结束了，不会再执行其他的代理方法；如果允许，那么就会执行开始加载的代理方法，执行完开始加载的代理方法的时候再执行这个代理方法。

根据意思可知，它的作用就是要根据导航的返回信息来判断是否加载网页。我们首先打印出navigationResponse的信息:

```
<WKNavigationResponse: 0x100323e50; response = <NSHTTPURLResponse: 0x170226780> { URL: https://www.baidu.com/ } { status code: 200, headers {
    "Cache-Control" = "no-cache";
    Connection = "keep-alive";
    "Content-Encoding" = gzip;
    "Content-Length" = 20059;
    "Content-Type" = "text/html;charset=utf-8";
    Date = "Mon, 27 Mar 2017 05:29:56 GMT";
    Server = "bfe/1.0.8.18";
    "Set-Cookie" = "H_WISE_SIDS=108266_100186_114821_114654_114743_109815_103550_114996_114701_112106_107314_114132_115245_115109_115056_115244_115043_114797_114513_114998_115227_114329_114534_115032_114276_114975_110085; path=/; domain=.baidu.com, BDSVRTM=182; path=/, __bsi=11762462753482193024_00_281_N_N_189_0303_C02F_N_N_Y_0; expires=Mon, 27-Mar-17 05:30:01 GMT; domain=www.baidu.com; path=/";
    "Strict-Transport-Security" = "max-age=172800";
    Traceid = 149059259607016350822661639119137312881;
} }>
```

这个response有个属性叫做forMainFrame，用于标识导航的frame是不是主frame。

navigationResponse的canShowMIMEType属性用于表示WebKit是否能够展示返回的MIME类型。

如果我们拿到了返回的信息，发现这些信息我们不需要，我们可以在此方法里面进行处理，然后决定是否加载该网页。

接下来执行的是（WKN4）：

```
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation;
```

这个代理方法是在网页开始接受网络内容的时候调用，也就是网络内容开始要往网页中加载。

再接着就是（WKN5）：

```
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
```

意思就是这个导航我们已经加载完成了。我的理解就是这个当前网页加载完毕。

 还有剩下的三个方法，一个加载网页失败的方法，一个接收服务器跳转方法和一个网页加载进程终止的方法。

网页加载失败方法：

```
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
```

当网页由于error加载失败就会调用这个代理方法，它会将具体的error信息给抛出，然后供开发者具体情况具体处理。这里的error code具体在NSURLError.h里面定义，具体为：

![img](http://images.cnblogs.com/OutliningIndicators/ContractedBlock.gif)View Code

这里有个小小的问题需要说明一下：

当我是用[这个URL](https://www.shuquwangluo.com/loannav/index.html?app=1&uid=1234)来进行加载的时候。我点击进去一个连接，然后再返回上一个页面的时候，发现会执行加载失败，查看原因是-999，也就是NSURLErrorCancelled。我理解的应该是因为之前上一个网页已经加载过了，再次加载的时候发现已经加载过了，所以这次返回上一个页面会报一个加载取消，应该是webview发现要加载的这个网页之前已经加载过，然后就取消了这个加载，加载了缓存。

另外两个代理方法：

```
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
```

和

```
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0));
```

前者重定向跳转我们也许会经常遇到，但是一般不怎么去处理其内容，这里就不在介绍了，后者进程终止这个我也不太清楚怎么去触发，也就不再介绍了。

 接下来就来看一下各个代理方法的执行顺序（直接跑百度）：

```
2017-03-27 14:16:22.028051 WKWebViewDemo[561:39556] 是否允许这个导航
2017-03-27 14:16:22.028486 WKWebViewDemo[561:39556] 开始加载
2017-03-27 14:16:24.102160 WKWebViewDemo[561:39556] 知道返回内容之后，是否允许加载，允许加载
2017-03-27 14:16:24.106276 WKWebViewDemo[561:39556] 网页开始接收网页内容
2017-03-27 14:16:29.156518 WKWebViewDemo[561:39556] 网页导航加载完毕
2017-03-27 14:16:29.177006 WKWebViewDemo[561:39556] ----document.title:百度一下---webView title:百度一下
```

这就是顺序了。

忘了还有一个身份验证的：

```
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler;
```

具体没做了解，以后如果用到会进一步补充，这里感兴趣的也可以自己看一下。

二.WKUIDelegate 

该协议的代理方法的作用是使用原生的用户界面来代表网页。 说白了就是我们去手动写新加载页面的UI、alert框的样式、对话框的样式等等。直接拿下面的例子来看：

```
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
```

首先来看一下：

```
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration 
forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;
```

在上面也提到了，如果我们新打开了一个tab，就会调用此方法。如果我们打开tab但是没有实现这个方法，那么网页就会取消这个导航，也就是没有做出任何反应。所以使用WKWebView的时候一定要记得对这个方法进行处理，如果没有处理也许就会导致点击网页没有任何反应。此时可以这样处理：

```
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSLog(@"创建一个新的webView");
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
```

这样做就是说如果是新打开的网页，那么我们可以直接在当前网页去加载要load的请求，然后返回nil，这样就是在当前的网页去打开新的tab页面了。也可以直接判断targetFrame是否空来进行loadRequest。

当我们的网页中调用alert()方法的时候，我们就要去实现：

```
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;
```

如果我们没有实现这个方法，那么alert是没有办法弹出来的（我这边测试的是弹不出来）。因此我们可以这样实现此代理方法：

```
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"alert" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
```

我们将alert的UI设置为我们系统的UIAlertController。这里的message就是要alert出来的数据信息。

接下来是：

```
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    completionHandler(YES);
}
```

此方法的作用是展示一个js确认框。这里的completionHandler的回调是确认框的yes or no。例如一个网页的按钮处理操作如下：

```
 // confirm选择框
                function firm() {
                    var r=confirm("Press a button")
                    if (r==true)
                    {
                        document.write("You pressed OK!")
                    }
                    else
                    {
                        document.write("You pressed Cancel!")
                    }
                }
                
```

如果我们传入的是YES，那么就会执行“You pressed OK”，否则就是执行“You pressed Cancel”。

接下来是：

```
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt 
defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler;
```

这里如果我们不去手动实现该方法，那么点击的动作就像我们点击取消，是一样的效果。

例如 在HTML中button的click方法如下：

```
function prom() {
      var result = prompt("演示一个带输入的对话框", "请输入内容");
         if(result) {
               alert("谢谢使用，你输入的是：" + result)
         }
}
```

那么这个result就是我们在上面的代理方法里面传入的result。例如：

```
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler {
    completionHandler(@"oc对象");
}
```

那么他就会弹出：“谢谢使用，你输入的是oc对象”。

其实这里我们可以对上面的三个代理方法进行深度定制UI，那么就能按照我们原生的UI显示出来效果。

当我们设置WKWebView的属性allowsLinkPreview为YES的时候，那么我们就可以进行3D touch预览。默认的值是NO。如果我们设置YES，但是：

```
- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo {
    return NO;
}
```

此代理方法中返回NO，那么依然无法展示预览视图，因为该代理方法的作用就是决定是否允许加载预览视图。（safari默认是支持3D touch预览的）。而：

```
- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions {
    return nil;
}
```

这个方法就是用于我们自己定义预览界面。另外还有：

```
- (void)webViewDidClose:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0));
```

和

```
- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0));
```

前者是DOM window成功关闭的时候调用。后者是当用户在预览中执行弹出操作时调用。

四.总结

简单就对WKWebView的代理介绍这么多，在后面如果有其他需要补充的再补充。
