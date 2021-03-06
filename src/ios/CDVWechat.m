//
//  CDVWechat.m
//  cordova-plugin-wechat
//
//
//

#import "CDVWechat.h"

static int const MAX_THUMBNAIL_SIZE = 320;

@implementation CDVWechat

NSString *body=@"";

#pragma mark "API"
- (void)pluginInitialize {
    NSString* appId = [[self.commandDelegate settings] objectForKey:@"wechatappid"];
    NSString* appSecret = [[self.commandDelegate settings] objectForKey:@"wechatappsecret"];
    if(appSecret){
        self.wechatAppSecret=appSecret;
    }
    if(appId){
        self.wechatAppId = appId;
        [WXApi registerApp: appId];
    }   
}

- (void)isWXAppInstalled:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[WXApi isWXAppInstalled]];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)share:(CDVInvokedUrlCommand *)command
{
    // if not installed
    if (![WXApi isWXAppInstalled])
    {
        [self failWithCallbackID:command.callbackId withMessage:@"未安装微信"];
        return ;
    }
    
    // check arguments
    NSDictionary *params = [command.arguments objectAtIndex:0];
    if (!params)
    {
        [self failWithCallbackID:command.callbackId withMessage:@"参数格式错误"];
        return ;
    }
    
    // save the callback id
    self.currentCallbackId = command.callbackId;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    
    // check the scene
    if ([params objectForKey:@"scene"])
    {
        req.scene = (int)[[params objectForKey:@"scene"] integerValue];
    }
    else
    {
        req.scene = WXSceneTimeline;
    }
    
    // message or text?
    NSDictionary *message = [params objectForKey:@"message"];
    
    if (message)
    {
        req.bText = NO;
        
        // async
        [self.commandDelegate runInBackground:^{
            req.message = [self buildSharingMessage:message];
            if (![WXApi sendReq:req])
            {
                [self failWithCallbackID:command.callbackId withMessage:@"发送请求失败"];
                self.currentCallbackId = nil;
            }
        }];
    }
    else
    {
        req.bText = YES;
        req.text = [params objectForKey:@"text"];
        
        if (![WXApi sendReq:req])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"发送请求失败"];
            self.currentCallbackId = nil;
        }
    }
}

- (void)sendAuthRequest:(CDVInvokedUrlCommand *)command
{
    SendAuthReq* req =[[SendAuthReq alloc] init];
    
    // scope
    if ([command.arguments count] > 0)
    {
        req.scope = [command.arguments objectAtIndex:0];
    }
    else
    {
        req.scope = @"snsapi_userinfo";
    }
    
    // state
    if ([command.arguments count] > 1)
    {
        req.state = [command.arguments objectAtIndex:1];
    }
    
    if ([WXApi sendReq:req])
    {
        // save the callback id
        self.currentCallbackId = command.callbackId;
    }
    else
    {
        [self failWithCallbackID:command.callbackId withMessage:@"发送请求失败，检查是否安装微信客户端"];
    }
}

- (void)sendPaymentRequest:(CDVInvokedUrlCommand *)command
{
    // check arguments
    
    NSDictionary *params = [command.arguments objectAtIndex:0];
    if (!params)
    {
        [self failWithCallbackID:command.callbackId withMessage:@"参数格式错误"];
        return ;
    }
    
    // check required parameters
    NSArray *requiredParams;
    if ([params objectForKey:@"mch_id"])
    {
        requiredParams = @[@"mch_id", @"prepay_id", @"timestamp", @"nonce_str", @"sign"];
    }
    else
    {
        requiredParams = @[@"partnerid", @"prepayid", @"timestamp", @"noncestr", @"sign",@"body"];
    }
    
    for (NSString *key in requiredParams)
    {
        if (![params objectForKey:key])
        {
            [self failWithCallbackID:command.callbackId withMessage:@"参数格式错误"];
            return ;
        }
    }
    
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = [params objectForKey:requiredParams[0]];
    req.prepayId = [params objectForKey:requiredParams[1]];
    req.timeStamp = [[params objectForKey:requiredParams[2]] intValue];
    req.nonceStr = [params objectForKey:requiredParams[3]];
    req.package = @"Sign=WXPay";
    req.sign = [params objectForKey:requiredParams[4]];
    
    body = [params objectForKey:requiredParams[5]];

    if ([WXApi sendReq:req])
    {
        // save the callback id
        self.currentCallbackId = command.callbackId;
    }
    else
    {
        [self failWithCallbackID:command.callbackId withMessage:@"发送请求失败，检查是否安装微信客户端"];
    }
}

#pragma mark "WXApiDelegate"

/**
 * Not implemented
 */
- (void)onReq:(BaseReq *)req
{
    NSLog(@"%@", req);
}

- (void)onResp:(BaseResp *)resp
{
    BOOL success = NO;
    NSString *message = @"Unknown";
    NSDictionary *response = nil;
    
    switch (resp.errCode)
    {
        case WXSuccess:
            success = YES;
            break;
            
        case WXErrCodeCommon:
            message = @"普通错误";
            break;
            
        case WXErrCodeUserCancel:
            message = @"用户点击取消并返回";
            break;
            
        case WXErrCodeSentFail:
            message = @"发送失败";
            break;
            
        case WXErrCodeAuthDeny:
            message = @"授权失败";
            break;
            
        case WXErrCodeUnsupport:
            message = @"微信不支持";
            break;

        default:
            message = @"未知错误";
    }
    
    if (success)
    {
        if ([resp isKindOfClass:[SendAuthResp class]])
        {
            // fix issue that lang and country could be nil for iPhone 6 which caused crash.
            SendAuthResp* authResp = (SendAuthResp*)resp;
             
            NSString *code=authResp.code;
            NSString *state=authResp.state;
            NSString *lang=authResp.lang;
            NSString *country=authResp.country;
            
            ////////////////////////获取token///////////////
            //NSString *APPSecret=@"7c3213677c04109f622f71598e4bd62c";
            
            NSString *APPSecret=@"d95f4bf4c6868cd92f8c8cb74ab4a2a8";
            
            
            //[NSString initWithFormat:@"%@,%@", string1, string2 ];
            NSString *baseUrl=@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=";
            NSString *APPSecretUrl=@"&secret=";
            NSString *codeUrl=@"&code=";
            NSString *typeUrl=@"&grant_type=authorization_code";

            NSString *string =@"";
            //string=[string stringByAppendingFormat:@"%@%@%@%@%@%@%@",baseUrl,self.wechatAppId,APPSecretUrl,APPSecret,codeUrl,code,typeUrl];
            string=[string stringByAppendingFormat:@"%@%@%@%@%@%@%@",baseUrl,self.wechatAppId,APPSecretUrl,self.wechatAppSecret,codeUrl,code,typeUrl];
            
            NSURL *url = [NSURL URLWithString:string];
            
            NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
            NSString *str = [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
            NSLog(@"%@",str);
           
            
            NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

            NSString * access_token=[json objectForKey:@"access_token"];
            NSString * expires_in=[json objectForKey:@"expires_in"];
            NSString * refresh_token=[json objectForKey:@"refresh_token"];
            NSString * openid=[json objectForKey:@"openid"];
            NSString * scope=[json objectForKey:@"scope"];
            NSString * unionid=[json objectForKey:@"unionid"];
            ////////////////////////获取token///////////////
            
            ////////////////////////获取个人资料///////////////
            //String urlUnionIDstr="https://api.weixin.qq.com/sns/userinfo?access_token="+access_token+"&openid="+openid;
            NSString *userUrl=@"https://api.weixin.qq.com/sns/userinfo?access_token=";
            NSString *openidUrl=@"&openid=";
            userUrl=[userUrl stringByAppendingFormat:@"%@%@%@%",access_token,openidUrl,openid];
            NSURL *userurl = [NSURL URLWithString:userUrl];
            
            NSURLRequest *userrequest = [[NSURLRequest alloc]initWithURL:userurl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
            NSData *userreceived = [NSURLConnection sendSynchronousRequest:userrequest returningResponse:nil error:nil];
            NSString *userstr = [[NSString alloc]initWithData:userreceived encoding:NSUTF8StringEncoding];
            NSLog(@"%@",userstr);
            
            NSData *userdata = [userstr dataUsingEncoding:NSUTF8StringEncoding];
            id userjson = [NSJSONSerialization JSONObjectWithData:userdata options:0 error:nil];
            
            NSString *  nickname =[userjson objectForKey:@"nickname"];
            NSString *  sex=[userjson objectForKey:@"sex"];
            NSString *  language=[userjson objectForKey:@"language"];
            NSString *  city=[userjson objectForKey:@"city"];
            NSString *  province=[userjson objectForKey:@"province"];
            NSString *  headimgurl=[userjson objectForKey:@"headimgurl"];
            NSString *  privilege=[userjson objectForKey:@"privilege"];

            
            
            ////////////////////////获取个人资料///////////////
            
            
            response = @{
                         @"code": authResp.code != nil ? authResp.code : @"",
                         @"state": authResp.state != nil ? authResp.state : @"",
                         @"lang": authResp.lang != nil ? authResp.lang : @"",
                         @"country": authResp.country != nil ? authResp.country : @"",
                         @"access_token": access_token !=nil ? access_token   :@"",
                         @"openid": openid !=nil ?  openid  :@"",
                         @"scope": scope!=nil ?  scope  :@"",
                         @"expires_in": expires_in!=nil ?  expires_in  :@"",
                         @"unionid":unionid !=nil ?  unionid  :@"",
                         @"refresh_token": refresh_token!=nil ?   refresh_token :@"",
                         @"nickname":nickname !=nil ?  nickname  :@"",
                         @"sex": sex!=nil ?   sex :@"",
                         @"language": language!=nil ?   language :@"",
                         @"city":city !=nil ?  city  :@"",
                         @"province": province!=nil ?   province :@"",
                         @"headimgurl": headimgurl!=nil ?   headimgurl :@"",
                         @"privilege": privilege!=nil ?    privilege:@"",
                         };
            
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            
            [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
        }
        else  if ([resp isKindOfClass:[PayResp class]])
        {
            response = @{
                         @"body": body,
                         @"state":@"success",
                         };
            
            CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
            
            [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentCallbackId];
        }
        else
        {
            [self successWithCallbackID:self.currentCallbackId];
        }
    }
    else{
        [self failWithCallbackID:self.currentCallbackId withMessage:message];
    }
    
    self.currentCallbackId = nil;
}

#pragma mark "CDVPlugin Overrides"

- (void)handleOpenURL:(NSNotification *)notification
{
    NSURL* url = [notification object];
    
    if ([url isKindOfClass:[NSURL class]] && [url.scheme isEqualToString:self.wechatAppId])
    {
        [WXApi handleOpenURL:url delegate:self];
    }
}

#pragma mark "Private methods"

- (WXMediaMessage *)buildSharingMessage:(NSDictionary *)message
{
    WXMediaMessage *wxMediaMessage = [WXMediaMessage message];
    wxMediaMessage.title = [message objectForKey:@"title"];
    wxMediaMessage.description = [message objectForKey:@"description"];
    wxMediaMessage.mediaTagName = [message objectForKey:@"mediaTagName"];
    wxMediaMessage.messageExt = [message objectForKey:@"messageExt"];
    wxMediaMessage.messageAction = [message objectForKey:@"messageAction"];
    if ([message objectForKey:@"thumb"])
    {
        [wxMediaMessage setThumbImage:[self getUIImageFromURL:[message objectForKey:@"thumb"]]];
    }
    
    // media parameters
    id mediaObject = nil;
    NSDictionary *media = [message objectForKey:@"media"];
    
    // check types
    NSInteger type = [[media objectForKey:@"type"] integerValue];
    switch (type)
    {
        case CDVWXSharingTypeApp:
            mediaObject = [WXAppExtendObject object];
            ((WXAppExtendObject*)mediaObject).extInfo = [media objectForKey:@"extInfo"];
            ((WXAppExtendObject*)mediaObject).url = [media objectForKey:@"url"];
            break;
            
        case CDVWXSharingTypeEmotion:
            mediaObject = [WXEmoticonObject object];
            ((WXEmoticonObject*)mediaObject).emoticonData = [self getNSDataFromURL:[media objectForKey:@"emotion"]];
            break;
            
        case CDVWXSharingTypeFile:
            mediaObject = [WXFileObject object];
            ((WXFileObject*)mediaObject).fileData = [self getNSDataFromURL:[media objectForKey:@"file"]];
            break;
            
        case CDVWXSharingTypeImage:
            mediaObject = [WXImageObject object];
            ((WXImageObject*)mediaObject).imageData = [self getNSDataFromURL:[media objectForKey:@"image"]];
            break;
            
        case CDVWXSharingTypeMusic:
            mediaObject = [WXMusicObject object];
            ((WXMusicObject*)mediaObject).musicUrl = [media objectForKey:@"musicUrl"];
            ((WXMusicObject*)mediaObject).musicDataUrl = [media objectForKey:@"musicDataUrl"];
            break;
            
        case CDVWXSharingTypeVideo:
            mediaObject = [WXVideoObject object];
            ((WXVideoObject*)mediaObject).videoUrl = [media objectForKey:@"videoUrl"];
            break;
            
        case CDVWXSharingTypeWebPage:
        default:
            mediaObject = [WXWebpageObject object];
            ((WXWebpageObject *)mediaObject).webpageUrl = [media objectForKey:@"webpageUrl"];
    }
    
    wxMediaMessage.mediaObject = mediaObject;
    return wxMediaMessage;
}

- (NSData *)getNSDataFromURL:(NSString *)url
{
    NSData *data = nil;
    
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"])
    {
        data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    }
    else if ([url hasPrefix:@"data:image"])
    {
        // a base 64 string
        NSURL *base64URL = [NSURL URLWithString:url];
        data = [NSData dataWithContentsOfURL:base64URL];
    }
    else if ([url rangeOfString:@"temp:"].length != 0)
    {
        url =  [NSTemporaryDirectory() stringByAppendingPathComponent:[url componentsSeparatedByString:@"temp:"][1]];
        data = [NSData dataWithContentsOfFile:url];
    }
    else
    {
        // local file
        url = [[NSBundle mainBundle] pathForResource:[url stringByDeletingPathExtension] ofType:[url pathExtension]];
        data = [NSData dataWithContentsOfFile:url];
    }
    
    return data;
}

- (UIImage *)getUIImageFromURL:(NSString *)url
{
    NSData *data = [self getNSDataFromURL:url];
    UIImage *image = [UIImage imageWithData:data];
    
    if (image.size.width > MAX_THUMBNAIL_SIZE || image.size.height > MAX_THUMBNAIL_SIZE)
    {
        CGFloat width = 0;
        CGFloat height = 0;
        
        // calculate size
        if (image.size.width > image.size.height)
        {
            width = MAX_THUMBNAIL_SIZE;
            height = width * image.size.height / image.size.width;
        }
        else
        {
            height = MAX_THUMBNAIL_SIZE;
            width = height * image.size.width / image.size.height;
        }
        
        // scale it
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [image drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *scaled = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaled;
    }
    
    return image;
}

- (void)successWithCallbackID:(NSString *)callbackID
{
    [self successWithCallbackID:callbackID withMessage:@"OK"];
}

- (void)successWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

- (void)failWithCallbackID:(NSString *)callbackID withError:(NSError *)error
{
    [self failWithCallbackID:callbackID withMessage:[error localizedDescription]];
}

- (void)failWithCallbackID:(NSString *)callbackID withMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    [self.commandDelegate sendPluginResult:commandResult callbackId:callbackID];
}

@end
