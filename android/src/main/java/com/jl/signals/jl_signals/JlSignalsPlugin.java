package com.jl.signals.jl_signals;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.bytedance.ads.convert.BDConvert;
import com.bytedance.ads.convert.callback.BDConvertLifecycleCallback;
import com.bytedance.ads.convert.config.BDConvertConfig;
import com.bytedance.ads.convert.event.ConvertReportHelper;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** JlSignalsPlugin */
public class JlSignalsPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String CHANNEL_NAME = "jl_signals";

  private MethodChannel channel;
  private Context applicationContext;
  private Activity activity;
  private Handler mainHandler;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    applicationContext = binding.getApplicationContext();
    mainHandler = new Handler(Looper.getMainLooper());
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_NAME);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    try {
      switch (call.method) {
        case "initialize":
          initialize(call.argument("config"));
          result.success(null);
          break;
        case "sendLaunchEvent":
          BDConvert.INSTANCE.sendLaunchEvent(applicationContext);
          result.success(null);
          break;
        case "trackEvent":
          trackEvent(call.argument("name"), call.argument("params"));
          result.success(null);
          break;
        case "getClickId":
          result.success(null);
          break;
        case "getAndroidId":
          result.success(Settings.Secure.getString(
              applicationContext.getContentResolver(),
              Settings.Secure.ANDROID_ID
          ));
          break;
        case "getIdfv":
          result.success(null);
          break;
        case "requestTrackingAuthorization":
          result.success("unsupported");
          break;
        case "handleDeeplink":
        case "enableIdfa":
        case "enablePurchaseEvent":
        case "registerOptionalData":
          // 这些能力在当前文档中由 iOS SDK 提供，Android 侧保持空实现。
          result.success(null);
          break;
        default:
          result.notImplemented();
          break;
      }
    } catch (Throwable throwable) {
      result.error("jl_signals_error", throwable.getMessage(), null);
    }
  }

  private void initialize(Map<String, Object> configMap) {
    BDConvertConfig config = buildConfig(configMap);
    boolean autoSendLaunchEvent = boolValue(configMap, "autoSendLaunchEvent", true);

    if (autoSendLaunchEvent) {
      if (activity == null) {
        throw new IllegalStateException("BDConvert init needs a foreground Activity.");
      }
      BDConvert.INSTANCE.init(applicationContext, config, activity);
    } else {
      Application app = (Application) applicationContext.getApplicationContext();
      BDConvert.INSTANCE.init(app, config);
    }
  }

  private BDConvertConfig buildConfig(Map<String, Object> configMap) {
    BDConvertConfig config = new BDConvertConfig();
    config.setAutoSendLaunchEvent(boolValue(configMap, "autoSendLaunchEvent", true));
    config.setEnableLog(boolValue(configMap, "enableLog", false));
    config.setPlaySessionEnable(boolValue(configMap, "playSessionEnable", true));
    config.setEnableOAID(boolValue(configMap, "enableOaid", true));

    String customOaid = stringValue(configMap, "customOaid");
    if (!TextUtils.isEmpty(customOaid)) {
      config.setCustomOaidCallback(() -> customOaid);
    }

    String customAndroidId = stringValue(configMap, "customAndroidId");
    if (!TextUtils.isEmpty(customAndroidId)) {
      config.setCustomAndroidIDCallback(() -> customAndroidId);
    }

    config.setLifecycleCallback(new BDConvertLifecycleCallback() {
      @Override
      public void onInitSuccess() {
        sendNativeCallback("onInitSuccess", null);
      }

      @Override
      public void onInitFailure(int reason, Throwable throwable) {
        Map<String, Object> data = new HashMap<>();
        data.put("reason", reason);
        data.put("error", throwable == null ? null : throwable.getMessage());
        sendNativeCallback("onInitFailure", data);
      }

      @Override
      public void onEventSendSuccess(String eventName, String eventId) {
        Map<String, Object> data = new HashMap<>();
        data.put("eventName", eventName);
        data.put("eventId", eventId);
        sendNativeCallback("onEventSendSuccess", data);
      }

      @Override
      public void onEventSendFailure(
          String eventName,
          int reason,
          String eventId,
          Throwable throwable
      ) {
        Map<String, Object> data = new HashMap<>();
        data.put("eventName", eventName);
        data.put("reason", reason);
        data.put("eventId", eventId);
        data.put("error", throwable == null ? null : throwable.getMessage());
        sendNativeCallback("onEventSendFailure", data);
      }

      @Override
      public void onOtherError(int reason, Throwable throwable) {
        Map<String, Object> data = new HashMap<>();
        data.put("reason", reason);
        data.put("error", throwable == null ? null : throwable.getMessage());
        sendNativeCallback("onOtherError", data);
      }
    });

    return config;
  }

  private void trackEvent(String name, Map<String, Object> params) {
    if (TextUtils.isEmpty(name)) {
      throw new IllegalArgumentException("Event name cannot be empty.");
    }
    JSONObject json = new JSONObject(params == null ? new HashMap<String, Object>() : params);
    ConvertReportHelper.onEventV3(name, json);
  }

  private void sendNativeCallback(String method, Map<String, Object> data) {
    if (channel == null || mainHandler == null) {
      return;
    }
    Map<String, Object> payload = new HashMap<>();
    payload.put("method", method);
    if (data != null) {
      payload.putAll(data);
    }
    if (Looper.myLooper() == Looper.getMainLooper()) {
      channel.invokeMethod("onNativeCallback", payload);
    } else {
      mainHandler.post(() -> {
        if (channel != null) {
          channel.invokeMethod("onNativeCallback", payload);
        }
      });
    }
  }

  private boolean boolValue(Map<String, Object> map, String key, boolean defaultValue) {
    if (map == null || !(map.get(key) instanceof Boolean)) {
      return defaultValue;
    }
    return (Boolean) map.get(key);
  }

  private String stringValue(Map<String, Object> map, String key) {
    if (map == null) {
      return null;
    }
    Object value = map.get(key);
    return value instanceof String ? (String) value : null;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (channel != null) {
      channel.setMethodCallHandler(null);
    }
    channel = null;
    mainHandler = null;
    applicationContext = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }
}
