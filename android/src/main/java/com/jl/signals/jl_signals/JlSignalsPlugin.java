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

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

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
  private String customOaid;

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
        case "getOaid":
          getOaid(result);
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
    this.customOaid = customOaid;
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

  private void getOaid(Result result) {
    if (!TextUtils.isEmpty(customOaid)) {
      result.success(customOaid);
      return;
    }
    if (applicationContext == null) {
      result.success(null);
      return;
    }

    new Thread(() -> {
      String oaid = readOaidFromBytedanceSdk(applicationContext);
      if (TextUtils.isEmpty(oaid)) {
        oaid = readOaidFromMsaSdk(applicationContext);
      }
      postResult(result, emptyToNull(oaid));
    }, "jl-signals-oaid").start();
  }

  private String readOaidFromBytedanceSdk(Context context) {
    String cachedOaid = readCachedBytedanceOaid(context);
    if (!TextUtils.isEmpty(cachedOaid)) {
      return cachedOaid;
    }

    try {
      Class<?> builderClass = Class.forName("com.bytedance.ads.convert.flat.k.b$a");
      Constructor<?> builderConstructor = builderClass.getConstructor(Context.class);
      Object builder = builderConstructor.newInstance(context);

      Class<?> resolverClass = Class.forName("com.bytedance.ads.convert.flat.k.b");
      Constructor<?> resolverConstructor = resolverClass.getConstructor(builderClass);
      Object resolver = resolverConstructor.newInstance(builder);

      Method resolve = resolverClass.getMethod(
          "a",
          Context.class,
          Class.forName("com.bytedance.ads.convert.flat.k.d")
      );
      Object resolved = resolve.invoke(resolver, context, null);
      return readBytedanceOaidResultId(resolved);
    } catch (Throwable ignored) {
      return null;
    }
  }

  private String readCachedBytedanceOaid(Context context) {
    try {
      Object storage = Class.forName("com.bytedance.ads.convert.flat.k.e")
          .getConstructor(Context.class)
          .newInstance(context);
      Method read = storage.getClass().getMethod("a");
      Object result = read.invoke(storage);
      return readBytedanceOaidResultId(result);
    } catch (Throwable ignored) {
      return null;
    }
  }

  private String readBytedanceOaidResultId(Object result) {
    if (result == null) {
      return null;
    }
    try {
      Field idField = result.getClass().getField("a");
      Object value = idField.get(result);
      return value instanceof String ? (String) value : null;
    } catch (Throwable ignored) {
      return null;
    }
  }

  private String readOaidFromMsaSdk(Context context) {
    try {
      Class<?> helperClass = Class.forName("com.bun.miitmdid.core.MdidSdkHelper");
      Class<?> listenerClass = findClass(
          "com.bun.miitmdid.interfaces.IIdentifierListener",
          "com.bun.supplier.IIdentifierListener"
      );
      if (listenerClass == null) {
        return null;
      }

      tryInitMsaLibrary(context);

      CountDownLatch latch = new CountDownLatch(1);
      AtomicBoolean completed = new AtomicBoolean(false);
      String[] oaidBox = new String[1];
      InvocationHandler handler = (proxy, method, args) -> {
        if ("OnSupport".equals(method.getName())) {
          Object supplier = findSupplierArgument(args);
          oaidBox[0] = readSupplierOaid(supplier);
          completed.set(true);
          latch.countDown();
        }
        return null;
      };
      Object listener = Proxy.newProxyInstance(
          listenerClass.getClassLoader(),
          new Class<?>[]{listenerClass},
          handler
      );

      Method initSdk = findInitSdkMethod(helperClass, listenerClass);
      if (initSdk == null) {
        return null;
      }
      initSdk.invoke(null, context, true, listener);

      if (!completed.get()) {
        latch.await(2500, TimeUnit.MILLISECONDS);
      }
      return oaidBox[0];
    } catch (ClassNotFoundException ignored) {
      return null;
    } catch (Throwable ignored) {
      return null;
    }
  }

  private void tryInitMsaLibrary(Context context) {
    try {
      Class<?> libraryClass = Class.forName("com.bun.miitmdid.core.JLibrary");
      Method initEntry = libraryClass.getMethod("InitEntry", Context.class);
      initEntry.invoke(null, context);
    } catch (Throwable ignored) {
      // Some MSA SDK versions do not require explicit JLibrary initialization.
    }
  }

  private Class<?> findClass(String... classNames) {
    for (String className : classNames) {
      try {
        return Class.forName(className);
      } catch (ClassNotFoundException ignored) {
        // Try the next known package name.
      }
    }
    return null;
  }

  private Method findInitSdkMethod(Class<?> helperClass, Class<?> listenerClass) {
    for (Method method : helperClass.getMethods()) {
      Class<?>[] parameterTypes = method.getParameterTypes();
      if (!"InitSdk".equals(method.getName()) || parameterTypes.length != 3) {
        continue;
      }
      if (Context.class.isAssignableFrom(parameterTypes[0])
          && parameterTypes[1] == boolean.class
          && parameterTypes[2].isAssignableFrom(listenerClass)) {
        return method;
      }
    }
    return null;
  }

  private Object findSupplierArgument(Object[] args) {
    if (args == null) {
      return null;
    }
    for (Object arg : args) {
      if (arg != null && !(arg instanceof Boolean)) {
        return arg;
      }
    }
    return null;
  }

  private String readSupplierOaid(Object supplier) {
    if (supplier == null) {
      return null;
    }
    try {
      for (String methodName : new String[]{"getOAID", "getOaid", "getOAId"}) {
        try {
          Method method = supplier.getClass().getMethod(methodName);
          Object value = method.invoke(supplier);
          if (value instanceof String && !TextUtils.isEmpty((String) value)) {
            return (String) value;
          }
        } catch (NoSuchMethodException ignored) {
          // Try the next common method spelling.
        }
      }
    } catch (Throwable ignored) {
      return null;
    } finally {
      try {
        Method shutDown = supplier.getClass().getMethod("shutDown");
        shutDown.invoke(supplier);
      } catch (Throwable ignored) {
        // Not all supplier implementations expose shutDown.
      }
    }
    return null;
  }

  private String emptyToNull(String value) {
    return TextUtils.isEmpty(value) ? null : value;
  }

  private void postResult(Result result, String value) {
    if (mainHandler == null || Looper.myLooper() == Looper.getMainLooper()) {
      result.success(value);
      return;
    }
    mainHandler.post(() -> result.success(value));
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
