package com.gli.zynm.wxapi;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.gli.zynm.R;
import com.tencent.mm.sdk.constants.ConstantsAPI;
import com.tencent.mm.sdk.modelbase.BaseReq;
import com.tencent.mm.sdk.modelbase.BaseResp;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

import org.json.JSONObject;
import org.tencent.wechat.Wechat;
import org.json.JSONException;


public class WXPayEntryActivity extends Activity implements IWXAPIEventHandler {
    private static final String TAG = "WXPayEntryActivity";

    private IWXAPI api;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        //setContentView(R.layout.pay_result);

        //api = WXAPIFactory.createWXAPI(this, Wechat.WXAPPID_PROPERTY_KEY);
        //api.handleIntent(getIntent(), this);

        api = WXAPIFactory.createWXAPI(this, "wx628cff02b44894b2", true);
        api.handleIntent(getIntent(), this);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        api.handleIntent(intent, this);
    }

    @Override
    public void onReq(BaseReq req) {

    }

    @Override
    public void onResp(BaseResp resp) {
        Log.d(TAG, "onPayFinish, errCode = " + resp.errCode);

        if (resp.getType() == ConstantsAPI.COMMAND_PAY_BY_WX) {
            Log.d(TAG, String.valueOf(resp.errCode));

            //AlertDialog.Builder builder = new AlertDialog.Builder(this);
            //builder.setTitle("tishi");
            //builder.setMessage( String.valueOf(resp.errCode) );
            //builder.show();

        }

        if (Wechat.instance.getCurrentCallbackContext() == null) {
            //startMainActivity();
            return ;
        }

        switch (resp.errCode) {
            case BaseResp.ErrCode.ERR_OK:
                switch (resp.getType()) {
                    case ConstantsAPI.COMMAND_SENDAUTH:
                        //auth(resp);
                        break;

                        case ConstantsAPI.COMMAND_PAY_BY_WX:
                            payres();
                            break;

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

    protected void payres() {

        final JSONObject response = new JSONObject();
        try{
            response.put("state", "success");
            response.put("body", Wechat.body);
        } catch (JSONException e) {
            Log.e(Wechat.TAG, e.getMessage());
        }

        Wechat.instance.getCurrentCallbackContext().success(response);

    }

}
