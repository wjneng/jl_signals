import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jl_signals/jl_signals.dart';
import 'package:jl_signals/jl_signals_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelJlSignals();
  const channel = MethodChannel('jl_signals');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall);
          if (methodCall.method == 'getClickId') {
            return 'click-1';
          }
          if (methodCall.method == 'getIdfv') {
            return 'idfv-1';
          }
          if (methodCall.method == 'getAndroidId') {
            return 'android-id-1';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize sends serialized config', () async {
    const config = JlSignalsConfig(
      autoSendLaunchEvent: false,
      enableLog: true,
      playSessionEnable: false,
      enableOaid: false,
      customOaid: 'oaid',
      customAndroidId: 'android-id',
      optionalData: <String, Object?>{'user_unique_id': 'u1'},
      enableIdfa: true,
    );

    await platform.initialize(config);

    expect(calls.single.method, 'initialize');
    expect(calls.single.arguments, <String, Object?>{
      'config': <String, Object?>{
        'autoSendLaunchEvent': false,
        'enableLog': true,
        'playSessionEnable': false,
        'enableOaid': false,
        'customOaid': 'oaid',
        'customAndroidId': 'android-id',
        'optionalData': <String, Object?>{'user_unique_id': 'u1'},
        'enableIdfa': true,
      },
    });
  });

  test('method names match public API', () async {
    await platform.enableIdfa(true);
    final trackingStatus = await platform.requestTrackingAuthorization();
    await platform.handleDeeplink('demo://open?clickid=1');
    final clickId = await platform.getClickId();
    await platform.registerOptionalData(<String, Object?>{'extra': 'value'});
    await platform.trackEvent(
      'purchase',
      params: <String, Object?>{'pay_amount': 2334},
    );
    await platform.enablePurchaseEvent();
    await platform.sendLaunchEvent();
    final idfv = await platform.getIdfv();
    final androidId = await platform.getAndroidId();

    expect(trackingStatus, JlTrackingAuthorizationStatus.notDetermined);
    expect(clickId, 'click-1');
    expect(idfv, 'idfv-1');
    expect(androidId, 'android-id-1');
    expect(calls.map((call) => call.method), <String>[
      'enableIdfa',
      'requestTrackingAuthorization',
      'handleDeeplink',
      'getClickId',
      'registerOptionalData',
      'trackEvent',
      'enablePurchaseEvent',
      'sendLaunchEvent',
      'getIdfv',
      'getAndroidId',
    ]);
  });
}
