import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'jl_signals.dart';
import 'jl_signals_method_channel.dart';

abstract class JlSignalsPlatform extends PlatformInterface {
  JlSignalsPlatform() : super(token: _token);

  static final Object _token = Object();

  static JlSignalsPlatform _instance = MethodChannelJlSignals();

  static JlSignalsPlatform get instance => _instance;

  static set instance(JlSignalsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize(JlSignalsConfig config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> enableIdfa(bool enabled) {
    throw UnimplementedError('enableIdfa() has not been implemented.');
  }

  Future<JlTrackingAuthorizationStatus> requestTrackingAuthorization() {
    throw UnimplementedError(
      'requestTrackingAuthorization() has not been implemented.',
    );
  }

  Future<void> handleDeeplink(String url) {
    throw UnimplementedError('handleDeeplink() has not been implemented.');
  }

  Future<String?> getClickId() {
    throw UnimplementedError('getClickId() has not been implemented.');
  }

  Future<void> registerOptionalData(Map<String, Object?> data) {
    throw UnimplementedError(
      'registerOptionalData() has not been implemented.',
    );
  }

  Future<void> trackEvent(String name, {Map<String, Object?>? params}) {
    throw UnimplementedError('trackEvent() has not been implemented.');
  }

  Future<void> enablePurchaseEvent() {
    throw UnimplementedError('enablePurchaseEvent() has not been implemented.');
  }

  Future<void> sendLaunchEvent() {
    throw UnimplementedError('sendLaunchEvent() has not been implemented.');
  }

  Future<String?> getIdfv() {
    throw UnimplementedError('getIdfv() has not been implemented.');
  }

  Future<String?> getAndroidId() {
    throw UnimplementedError('getAndroidId() has not been implemented.');
  }
}
