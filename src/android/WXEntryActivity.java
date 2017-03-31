package com.example.demo.wxapi;

import android.app.Activity;
import android.content.Intent;
import android.content.res.XmlResourceParser;
import android.os.Bundle;
import android.util.Log;


import com.example.demo.R;
import com.tencent.mm.sdk.constants.ConstantsAPI;
import com.tencent.mm.sdk.modelbase.BaseReq;
import com.tencent.mm.sdk.modelbase.BaseResp;
import com.tencent.mm.sdk.modelmsg.SendAuth;
import com.tencent.mm.sdk.openapi.IWXAPIEventHandler;


import org.json.JSONException;
import org.json.JSONObject;
import org.xmlpull.v1.XmlPullParserException;

import org.tencent.wechat.Wechat;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;





public class WXEntryActivity extends Activity implements IWXAPIEventHandler {
    private static final String TAG = "WXEntryActivity";
    public static String appId;


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i("wechat", "Auth request has been return successfully.");
        if (Wechat.instance.getWxAPI() == null) {
            startMainActivity();
        } else {
            Wechat.instance.getWxAPI().handleIntent(getIntent(), this);
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);

        setIntent(intent);

        if (Wechat.instance.getWxAPI() == null) {
            startMainActivity();
        } else {
            Wechat.instance.getWxAPI().handleIntent(intent, this);
        }
    }

    @Override
    public void onResp(BaseResp resp) {
        Log.d(Wechat.TAG, resp.toString());

        if (Wechat.instance.getCurrentCallbackContext() == null) {
            startMainActivity();
            return ;
        }

        switch (resp.errCode) {
            case BaseResp.ErrCode.ERR_OK:
                switch (resp.getType()) {
                    case ConstantsAPI.COMMAND_SENDAUTH:
                        auth(resp);
                        break;

                    //case ConstantsAPI.COMMAND_PAY_BY_WX:
                    default:
                        Wechat.instance.getCurrentCallbackContext().success();
                        break;
                }
                break;
            case BaseResp.ErrCode.ERR_USER_CANCEL:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_USER_CANCEL);
                break;
            case BaseResp.ErrCode.ERR_AUTH_DENIED:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_AUTH_DENIED);
                break;
            case BaseResp.ErrCode.ERR_SENT_FAILED:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_SENT_FAILED);
                break;
            case BaseResp.ErrCode.ERR_UNSUPPORT:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_UNSUPPORT);
                break;
            case BaseResp.ErrCode.ERR_COMM:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_COMMON);
                break;
            default:
                Wechat.instance.getCurrentCallbackContext().error(Wechat.ERROR_WECHAT_RESPONSE_UNKNOWN);
                break;
        }

        finish();
    }

    @Override
    public void onReq(BaseReq req) {
        finish();
    }

    protected String getAppSecret() {
        XmlResourceParser xmlp= getResources().getXml(R.xml.config);
        String name=null;
        String value=null;
        try {
            while (xmlp.getEventType()!=XmlResourceParser.END_DOCUMENT) {
                if(xmlp.getEventType()==XmlResourceParser.START_TAG){
                    if(xmlp.getName().equals("preference")){
                        name= xmlp.getAttributeValue(null, "name");
                        value=xmlp.getAttributeValue(null, "value");
                        //System.out.println(String.format("姓名：%s  年龄：%s",name,age));
                        if(name.equals("WECHATAPPSECRET"))
                            break;
                    }
                }
                xmlp.next();
            }

        } catch (IOException e) {
            e.printStackTrace();
        } catch (XmlPullParserException e) {
            e.printStackTrace();
        }
        this.appId=value;
        return this.appId;
    }

    protected String getAppId() {
        XmlResourceParser xmlp= getResources().getXml(R.xml.config);
        String name=null;
        String value=null;
        try {
            while (xmlp.getEventType()!=XmlResourceParser.END_DOCUMENT) {
                if(xmlp.getEventType()==XmlResourceParser.START_TAG){
                    if(xmlp.getName().equals("preference")){
                        name= xmlp.getAttributeValue(null, "name");
                        value=xmlp.getAttributeValue(null, "value");
                        System.out.println(String.format("姓名：%s  年龄：%s",name,value));
                        //if(name.equals("WECHATAPPSECRET"))
                        //break;
                        if(name.equals("WECHATAPPID"))
                            break;

                    }
                }
                xmlp.next();
            }

        } catch (IOException e) {
            e.printStackTrace();
        } catch (XmlPullParserException e) {
            e.printStackTrace();
        }
        this.appId=value;
        return this.appId;
    }

    protected void startMainActivity() {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setPackage(getApplicationContext().getPackageName());
        getApplicationContext().startActivity(intent);
    }

    protected void auth(BaseResp resp) {
        final SendAuth.Resp res = ((SendAuth.Resp) resp);
        Log.d(Wechat.TAG, res.toString());
        final  JSONObject response = new JSONObject();
        final String APPSecret=getAppSecret();
        final String APPId=getAppId();

        final String urlStr = "https://api.weixin.qq.com/sns/oauth2/access_token?appid="+APPId+"&secret="+APPSecret+
                "&code="+res.code+"&grant_type=authorization_code";
        /*-----------------------------------------------------------------------*/
        new Thread() {
            public void run() {

                String result = null;
                URL url = null;
                HttpURLConnection connection = null;
                InputStreamReader in = null;
                try {
                    url = new URL(urlStr);
                    connection = (HttpURLConnection) url.openConnection();
                    connection.setRequestMethod("GET");
                    connection.setReadTimeout(5000);
                    connection.setConnectTimeout(5000);
                    if(connection.getResponseCode()==200){
                        InputStream is = connection.getInputStream();
                    }
                    in = new InputStreamReader(connection.getInputStream());
                    BufferedReader bufferedReader = new BufferedReader(in);
                    StringBuffer strBuffer = new StringBuffer();
                    String line = null;
                    while ((line = bufferedReader.readLine()) != null) {
                        strBuffer.append(line);
                    }
                    result = strBuffer.toString();
                    JSONObject str=new JSONObject(result);
                    String openid=str.getString("openid");
                    String access_token=str.getString("access_token");
                    String expires_in=str.getString("expires_in");
                    String refresh_token=str.getString("refresh_token");
                    String scope=str.getString("scope");
                    String unionid=str.getString("unionid");
                    //https://api.weixin.qq.com/sns/userinfo?access_token=ACCESS_TOKEN&openid=OPENID
                    String urlUnionIDstr="https://api.weixin.qq.com/sns/userinfo?access_token="+access_token+"&openid="+openid;
                    URL urlUnionID=new URL(urlUnionIDstr);
                    HttpURLConnection connectionUnionID = null;
                    InputStreamReader inUnionID = null;
                    connectionUnionID= (HttpURLConnection) urlUnionID.openConnection();
                    inUnionID=new InputStreamReader(connectionUnionID.getInputStream());
                    BufferedReader bufferedinUnionID=new BufferedReader(inUnionID);
                    StringBuffer inUnionIDBuffer=new StringBuffer();
                    line = null;
                    while ((line = bufferedinUnionID.readLine()) != null) {
                        inUnionIDBuffer.append(line);
                    }
                    JSONObject UnionResult=new JSONObject(inUnionIDBuffer.toString());

                    String nickname=UnionResult.getString("nickname");
                    String sex=UnionResult.getString("sex");
                    String province=UnionResult.getString("province");
                    String city=UnionResult.getString("city");
                    String country=UnionResult.getString("country");
                    String headimgurl=UnionResult.getString("headimgurl");
                    String privilege=UnionResult.getString("privilege");

                    try {
                        response.put("code", res.code);
                        response.put("state", res.state);
                        response.put("country", res.country);
                        response.put("lang", res.lang);
                        response.put("openid", openid);
                        response.put("access_token", access_token);
                        response.put("expires_in", expires_in);
                        response.put("refresh_token", refresh_token);
                        response.put("scope", scope);
                        response.put("unionid", unionid);
                        response.put("nickname", nickname);
                        response.put("sex", sex);
                        response.put("province", province);
                        response.put("city", city);
                        response.put("country", country);
                        response.put("headimgurl", headimgurl);
                        response.put("privilege", privilege);
                        Log.e(Wechat.TAG, res.code);
                    } catch (JSONException e) {
                        Log.e(Wechat.TAG, e.getMessage());
                    }
                    Wechat.instance.getCurrentCallbackContext().success(response);
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    if (connection != null) {
                        connection.disconnect();
                    }
                    if (in != null) {
                        try {
                            in.close();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }

                }
            }
        }.start();
    }




}
