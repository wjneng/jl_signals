import 'package:flutter/foundation.dart';

import 'jl_signals_platform_interface.dart';

enum JlTrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  unsupported,
}

class JlSignalsConfig {
  const JlSignalsConfig({
    this.autoSendLaunchEvent = true,
    this.enableLog = false,
    this.playSessionEnable = true,
    this.enableOaid = true,
    this.customOaid,
    this.customAndroidId,
    this.optionalData = const <String, Object?>{},
    this.enableIdfa = false,
  });

  /// Android: init 后是否自动发送启动事件。
  final bool autoSendLaunchEvent;

  /// Android: 是否开启 SDK debug 日志。
  final bool enableLog;

  /// Android: 是否启用心跳事件。
  final bool playSessionEnable;

  /// Android: SDK 是否采集 OAID。
  final bool enableOaid;

  /// Android: 业务自定义 OAID。传入后 SDK 自身不再采集 OAID。
  final String? customOaid;

  /// Android: 业务自定义 Android ID。传入错误值会影响归因。
  final String? customAndroidId;

  /// iOS: 注入 SDK 的可选参数，例如业务用户 id。
  final Map<String, Object?> optionalData;

  /// iOS: 是否允许 SDK 获取 IDFA，默认不获取。
  final bool enableIdfa;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'autoSendLaunchEvent': autoSendLaunchEvent,
      'enableLog': enableLog,
      'playSessionEnable': playSessionEnable,
      'enableOaid': enableOaid,
      'customOaid': customOaid,
      'customAndroidId': customAndroidId,
      'optionalData': optionalData,
      'enableIdfa': enableIdfa,
    };
  }
}

class JlSignals {
  const JlSignals();

  Future<void> initialize({JlSignalsConfig config = const JlSignalsConfig()}) {
    return JlSignalsPlatform.instance.initialize(config);
  }

  Future<void> enableIdfa(bool enabled) {
    return JlSignalsPlatform.instance.enableIdfa(enabled);
  }

  /// iOS: 请求 AppTrackingTransparency 授权。
  ///
  /// Android 和其他平台返回 [JlTrackingAuthorizationStatus.unsupported]。
  /// 如需 IDFA，建议在用户同意隐私政策后、初始化 SDK 前调用。
  Future<JlTrackingAuthorizationStatus> requestTrackingAuthorization() {
    return JlSignalsPlatform.instance.requestTrackingAuthorization();
  }

  Future<void> handleDeeplink(String url) {
    return JlSignalsPlatform.instance.handleDeeplink(url);
  }

  Future<String?> getClickId() {
    return JlSignalsPlatform.instance.getClickId();
  }

  Future<void> registerOptionalData(Map<String, Object?> data) {
    return JlSignalsPlatform.instance.registerOptionalData(data);
  }

  Future<void> trackEvent(String name, {Map<String, Object?>? params}) {
    return JlSignalsPlatform.instance.trackEvent(name, params: params);
  }

  Future<void> enablePurchaseEvent() {
    return JlSignalsPlatform.instance.enablePurchaseEvent();
  }

  /// Android 接入方式 B：autoSendLaunchEvent=false 后单独发送启动事件。
  Future<void> sendLaunchEvent() {
    return JlSignalsPlatform.instance.sendLaunchEvent();
  }
}

class JlSignalDeviceIds {
  const JlSignalDeviceIds._();

  /// 当前平台的设备标识。
  ///
  /// iOS 返回 IDFV，Android 返回 ANDROID_ID，其他平台返回 null。
  /// 请在用户同意隐私政策后调用。
  static Future<String?> getDeviceId() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => getIdfv(),
      TargetPlatform.android => getAndroidId(),
      _ => Future<String?>.value(),
    };
  }

  /// iOS: IDFV。Android 返回 null。
  static Future<String?> getIdfv() {
    return JlSignalsPlatform.instance.getIdfv();
  }

  /// Android: ANDROID_ID。iOS 返回 null。
  static Future<String?> getAndroidId() {
    return JlSignalsPlatform.instance.getAndroidId();
  }

  /// Android: OAID。iOS 返回 null。
  ///
  /// 请在用户同意隐私政策后调用。部分设备、系统环境或未接入 OAID SDK 时会返回 null。
  static Future<String?> getOaid() {
    return JlSignalsPlatform.instance.getOaid();
  }
}
