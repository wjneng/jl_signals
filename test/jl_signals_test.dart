import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jl_signals/jl_signals.dart';
import 'package:jl_signals/jl_signals_method_channel.dart';
import 'package:jl_signals/jl_signals_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJlSignalsPlatform
    with MockPlatformInterfaceMixin
    implements JlSignalsPlatform {
  JlSignalsConfig? lastConfig;
  bool? lastIdfaEnabled;
  JlTrackingAuthorizationStatus trackingStatus =
      JlTrackingAuthorizationStatus.notDetermined;
  String? lastDeeplink;
  Map<String, Object?>? lastOptionalData;
  String? lastEventName;
  Map<String, Object?>? lastEventParams;
  bool purchaseEnabled = false;
  bool launchSent = false;

  @override
  Future<void> initialize(JlSignalsConfig config) async {
    lastConfig = config;
  }

  @override
  Future<void> enableIdfa(bool enabled) async {
    lastIdfaEnabled = enabled;
  }

  @override
  Future<JlTrackingAuthorizationStatus> requestTrackingAuthorization() async {
    trackingStatus = JlTrackingAuthorizationStatus.authorized;
    return trackingStatus;
  }

  @override
  Future<void> handleDeeplink(String url) async {
    lastDeeplink = url;
  }

  @override
  Future<String?> getClickId() async {
    return 'click-1';
  }

  @override
  Future<void> registerOptionalData(Map<String, Object?> data) async {
    lastOptionalData = data;
  }

  @override
  Future<void> trackEvent(String name, {Map<String, Object?>? params}) async {
    lastEventName = name;
    lastEventParams = params;
  }

  @override
  Future<void> enablePurchaseEvent() async {
    purchaseEnabled = true;
  }

  @override
  Future<void> sendLaunchEvent() async {
    launchSent = true;
  }

  @override
  Future<String?> getIdfv() async {
    return 'idfv-1';
  }

  @override
  Future<String?> getAndroidId() async {
    return 'android-id-1';
  }
}

void main() {
  final JlSignalsPlatform initialPlatform = JlSignalsPlatform.instance;

  test('$MethodChannelJlSignals is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJlSignals>());
  });

  test(
    'JlSignals forwards public methods to platform implementation',
    () async {
      const jlSignals = JlSignals();
      final fakePlatform = MockJlSignalsPlatform();
      JlSignalsPlatform.instance = fakePlatform;

      const config = JlSignalsConfig(
        enableLog: true,
        enableIdfa: true,
        optionalData: <String, Object?>{'user_unique_id': 'u1'},
      );

      await jlSignals.initialize(config: config);
      await jlSignals.enableIdfa(true);
      final trackingStatus = await jlSignals.requestTrackingAuthorization();
      await jlSignals.handleDeeplink('demo://open?clickid=1');
      final clickId = await jlSignals.getClickId();
      await jlSignals.registerOptionalData(<String, Object?>{'extra': 'value'});
      await jlSignals.trackEvent(
        'register',
        params: <String, Object?>{'method': 'phone'},
      );
      await jlSignals.enablePurchaseEvent();
      await jlSignals.sendLaunchEvent();
      final idfv = await JlSignalDeviceIds.getIdfv();
      final androidId = await JlSignalDeviceIds.getAndroidId();

      expect(fakePlatform.lastConfig, config);
      expect(fakePlatform.lastIdfaEnabled, isTrue);
      expect(trackingStatus, JlTrackingAuthorizationStatus.authorized);
      expect(fakePlatform.lastDeeplink, 'demo://open?clickid=1');
      expect(clickId, 'click-1');
      expect(fakePlatform.lastOptionalData, <String, Object?>{
        'extra': 'value',
      });
      expect(fakePlatform.lastEventName, 'register');
      expect(fakePlatform.lastEventParams, <String, Object?>{
        'method': 'phone',
      });
      expect(fakePlatform.purchaseEnabled, isTrue);
      expect(fakePlatform.launchSent, isTrue);
      expect(idfv, 'idfv-1');
      expect(androidId, 'android-id-1');
    },
  );

  test('JlSignalDeviceIds returns current platform device id', () async {
    final fakePlatform = MockJlSignalsPlatform();
    JlSignalsPlatform.instance = fakePlatform;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await JlSignalDeviceIds.getDeviceId(), 'idfv-1');

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(await JlSignalDeviceIds.getDeviceId(), 'android-id-1');

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(await JlSignalDeviceIds.getDeviceId(), isNull);
  });
}
