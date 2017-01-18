//
//  CDVWechat.h
//  cordova-plugin-wechat
//
//
//

#import <Cordova/CDV.h>
#import "WXApi.h"
#import "WXApiObject.h"

enum  CDVWechatSharingType {
    CDVWXSharingTypeApp = 1,
    CDVWXSharingTypeEmotion,
    CDVWXSharingTypeFile,
    CDVWXSharingTypeImage,
    CDVWXSharingTypeMusic,
    CDVWXSharingTypeVideo,
    CDVWXSharingTypeWebPage
};

@interface CDVWechat:CDVPlugin <WXApiDelegate>

@property (nonatomic, strong) NSString *currentCallbackId;
@property (nonatomic, strong) NSString *wechatAppId;
@property (nonatomic, strong) NSString *wechatAppSecret;

- (void)isWXAppInstalled:(CDVInvokedUrlCommand *)command;
- (void)share:(CDVInvokedUrlCommand *)command;
- (void)sendAuthRequest:(CDVInvokedUrlCommand *)command;
- (void)sendPaymentRequest:(CDVInvokedUrlCommand *)command;

@end
