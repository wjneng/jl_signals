import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'jl_signals.dart';
import 'jl_signals_platform_interface.dart';

class MethodChannelJlSignals extends JlSignalsPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('jl_signals');

  @override
  Future<void> initialize(JlSignalsConfig config) {
    return methodChannel.invokeMethod<void>('initialize', <String, Object?>{
      'config': config.toMap(),
    });
  }

  @override
  Future<void> enableIdfa(bool enabled) {
    return methodChannel.invokeMethod<void>('enableIdfa', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<JlTrackingAuthorizationStatus> requestTrackingAuthorization() async {
    final status = await methodChannel.invokeMethod<String>(
      'requestTrackingAuthorization',
    );
    return JlTrackingAuthorizationStatus.values.firstWhere(
      (value) => value.name == status,
      orElse: () => JlTrackingAuthorizationStatus.notDetermined,
    );
  }

  @override
  Future<void> handleDeeplink(String url) {
    return methodChannel.invokeMethod<void>('handleDeeplink', <String, Object?>{
      'url': url,
    });
  }

  @override
  Future<String?> getClickId() {
    return methodChannel.invokeMethod<String>('getClickId');
  }

  @override
  Future<void> registerOptionalData(Map<String, Object?> data) {
    return methodChannel.invokeMethod<void>(
      'registerOptionalData',
      <String, Object?>{'data': data},
    );
  }

  @override
  Future<void> trackEvent(String name, {Map<String, Object?>? params}) {
    return methodChannel.invokeMethod<void>('trackEvent', <String, Object?>{
      'name': name,
      'params': params ?? const <String, Object?>{},
    });
  }

  @override
  Future<void> enablePurchaseEvent() {
    return methodChannel.invokeMethod<void>('enablePurchaseEvent');
  }

  @override
  Future<void> sendLaunchEvent() {
    return methodChannel.invokeMethod<void>('sendLaunchEvent');
  }

  @override
  Future<String?> getIdfv() {
    return methodChannel.invokeMethod<String>('getIdfv');
  }

  @override
  Future<String?> getAndroidId() {
    return methodChannel.invokeMethod<String>('getAndroidId');
  }
}
