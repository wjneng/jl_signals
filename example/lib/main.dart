import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jl_signals/jl_signals.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _signals = JlSignals();

  String _message = '等待操作';
  bool _initializing = false;
  bool _initialized = false;

  Future<void> _run(
    String successMessage,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = successMessage;
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message ?? error.code;
      });
    }
  }

  Future<void> _initializeAfterPrivacyConsent() async {
    setState(() {
      _initializing = true;
      _message = '初始化中';
    });

    await _run('已初始化并上报启动事件', () async {
      final trackingStatus = await _signals.requestTrackingAuthorization();
      await _signals.initialize(
        config: JlSignalsConfig(
          enableIdfa:
              trackingStatus == JlTrackingAuthorizationStatus.authorized,
          enableLog: true,
          optionalData: <String, Object?>{'user_unique_id': 'demo_user'},
        ),
      );
    });

    if (!mounted) {
      return;
    }
    setState(() {
      _initializing = false;
      _initialized = true;
    });
  }

  Future<void> _handleDeeplink() {
    return _run('已传递 deeplink', () {
      return _signals.handleDeeplink(
        'com.example.app://oceanengine/ads?clickid=demo_clickid',
      );
    });
  }

  Future<void> _getClickId() async {
    try {
      final clickId = await _signals.getClickId();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = clickId == null ? '暂无 clickid' : 'clickid: $clickId';
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message ?? error.code;
      });
    }
  }

  Future<void> _getDeviceIds() async {
    try {
      final deviceId = await JlSignalDeviceIds.getDeviceId();
      final idfv = await JlSignalDeviceIds.getIdfv();
      final androidId = await JlSignalDeviceIds.getAndroidId();
      final oaid = await JlSignalDeviceIds.getOaid();
      if (!mounted) {
        return;
      }
      setState(() {
        final lines = <String>[
          deviceId == null ? '当前平台设备标识: 暂无' : '当前平台设备标识: $deviceId',
          idfv == null ? 'IDFV: 暂无' : 'IDFV: $idfv',
          androidId == null ? 'Android ID: 暂无' : 'Android ID: $androidId',
          oaid == null ? 'OAID: 暂无' : 'OAID: $oaid',
        ];
        _message = lines.join('\n');
      });
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message ?? error.code;
      });
    }
  }

  Future<void> _trackRegister() {
    return _run('已上报注册事件', () {
      return _signals.trackEvent(
        'register',
        params: const <String, Object?>{'method': 'phone'},
      );
    });
  }

  Future<void> _trackPurchase() {
    return _run('已上报付费事件', () {
      return _signals.trackEvent(
        'purchase',
        params: const <String, Object?>{'pay_amount': 2334},
      );
    });
  }

  Future<void> _enablePurchaseEvent() {
    return _run('已开启 iOS 支付事件监听', _signals.enablePurchaseEvent);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('jl_signals example')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(_message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _initializing
                    ? null
                    : _initializeAfterPrivacyConsent,
                child: Text(_initialized ? '重新初始化' : '同意隐私政策并初始化'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _initialized ? _handleDeeplink : null,
                child: const Text('传递 Deeplink'),
              ),
              OutlinedButton(
                onPressed: _initialized ? _getClickId : null,
                child: const Text('获取 ClickId'),
              ),
              OutlinedButton(
                onPressed: _initialized ? _getDeviceIds : null,
                child: const Text('获取设备标识'),
              ),
              OutlinedButton(
                onPressed: _initialized ? _trackRegister : null,
                child: const Text('上报注册事件'),
              ),
              OutlinedButton(
                onPressed: _initialized ? _trackPurchase : null,
                child: const Text('上报付费事件'),
              ),
              OutlinedButton(
                onPressed: _initialized ? _enablePurchaseEvent : null,
                child: const Text('开启 iOS 支付监听'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
