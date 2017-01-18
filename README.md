# cordova-plugin-wechat

A cordova plugin, a JS version of Wechat SDK

# install
sudo cordova plugin add https://github.com/EiyouZk/PhoneGap-wechat-ThirdLogin.git --variable wechatappid=yourwechatappid WECHATAPPSECRET=yourWECHATAPPSECRET
# Feature

Share title, description, image, and link to wechat moment(朋友圈)


## Check if wechat is installed
```Javascript
Wechat.isInstalled(function (installed) {
    alert("Wechat installed: " + (installed ? "Yes" : "No"));
}, function (reason) {
    alert("Failed: " + reason);
});
```

## Authenticate using Wechat
```Javascript
var scope = "snsapi_userinfo";
Wechat.auth(scope, function (response) {
    // you may use response.code to get the access token.
    alert(JSON.stringify(response));
}, function (reason) {
    alert("Failed: " + reason);
});
```

## Share text
```Javascript
Wechat.share({
    text: "This is just a plain string",
    scene: Wechat.Scene.TIMELINE   // share to Timeline
}, function () {
    alert("Success");
}, function (reason) {
    alert("Failed: " + reason);
});
```

## Share media(e.g. link, photo, music, video etc)
```Javascript
Wechat.share({
    message: {
        title: "Hi, there",
        description: "This is description.",
        thumb: "www/img/thumbnail.png",
        mediaTagName: "TEST-TAG-001",
        messageExt: "这是第三方带的测试字段",
        messageAction: "<action>dotalist</action>",
        media: "YOUR_MEDIA_OBJECT_HERE"
    },
    scene: Wechat.Scene.TIMELINE   // share to Timeline
}, function () {
    alert("Success");
}, function (reason) {
    alert("Failed: " + reason);
});
```

### Share link
```Javascript
Wechat.share({
    message: {
        ...
        media: {
            type: Wechat.Type.LINK,
            webpageUrl: "http://tech.qq.com/zt2012/tmtdecode/252.htm"
        }
    },
    scene: Wechat.Scene.TIMELINE   // share to Timeline
}, function () {
    alert("Success");
}, function (reason) {
    alert("Failed: " + reason);
});
```

## Send payment request
```Javascript
var params = {
    partnerid: '10000100', // merchant id
    prepayid: 'wx201411101639507cbf6ffd8b0779950874', // prepay id
    noncestr: '1add1a30ac87aa2db72f57a2375d8fec', // nonce
    timestamp: '1439531364', // timestamp
    sign: '0CB01533B8C1EF103065174F50BCA001', // signed string
};

Wechat.sendPaymentRequest(params, function () {
    alert("Success");
}, function (reason) {
    alert("Failed: " + reason);
});
```
## 问题及解决方法总结：
（1）问题：java文件报引文件错误，找不到对应类。

     ```解决：在微信开放平台下载最新的jar包，引入到工程中。```
     
     
（2）问题：debug包可以拉起授权页面返回个人信息，但正式签名包拉不起授权页面。

     ```解决：在微信开放平台资源中心下载微信签名工具，在安装了正式包的手机上运行签名工具获取到签名和微信开放平台管理中心的的app详情里的应用签名对比。```
     
     
