# jl_signals 使用指南

`jl_signals` 是巨量引擎转化 SDK 的 Flutter 封装，用于在 Flutter App 中完成启动上报、deeplink clickid 解析、关键事件上报、设备标识读取等能力。

支持平台：

- Android 7.0/API 24 及以上
- iOS 13.0 及以上

## 1. 添加依赖

在业务项目的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  jl_signals: ^0.0.1
```

本地联调时可以临时改用 `path` 依赖，发布版本建议使用 pub.dev 托管版本。

## 2. Android 配置

在 Android 项目的仓库配置中加入巨量引擎 Maven 仓库。

Gradle Groovy 写法：

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url 'https://artifact.bytedance.com/repository/Volcengine/'
        }
    }
}
```

Gradle Kotlin DSL 写法：

```kotlin
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("https://artifact.bytedance.com/repository/Volcengine/")
    }
}
```

调用初始化、读取 Android ID、OAID 相关能力前，请确保用户已同意隐私政策。

## 3. iOS 配置

iOS 最低版本为 `13.0`。业务 App 的 `ios/Podfile` 需要满足：

```ruby
platform :ios, '13.0'
```

如业务需要获取 IDFA，宿主 App 必须在 `Info.plist` 中配置：

```xml
<key>NSUserTrackingUsageDescription</key>
<string>用于获取广告标识符以完成广告转化归因。</string>
```

如果 App 通过 URL Scheme 接收广告落地 deeplink，请按业务包名或已约定的 scheme 在宿主工程中配置 URL Types。

iOS 的隐私清单、App Store 隐私问卷、隐私政策内容需要按业务实际使用情况声明，尤其是 IDFA、追踪用途、巨量引擎转化 SDK 相关信息。

## 4. 初始化

必须在用户同意隐私政策后初始化。

```dart
import 'package:jl_signals/jl_signals.dart';

const signals = JlSignals();

Future<void> initSignals() async {
  final trackingStatus = await signals.requestTrackingAuthorization();

  await signals.initialize(
    config: JlSignalsConfig(
      enableIdfa: trackingStatus == JlTrackingAuthorizationStatus.authorized,
      enableLog: false,
      optionalData: <String, Object?>{
        'user_unique_id': '业务用户 id',
      },
    ),
  );
}
```

说明：

- `requestTrackingAuthorization()` 仅 iOS 会请求 ATT 授权；Android 返回 `unsupported`。
- `enableIdfa` 默认为 `false`。只有业务确实需要 IDFA，且用户已授权 ATT 时，才建议传 `true`。
- `optionalData` 用于传入业务侧额外参数，例如用户唯一标识。

## 5. Android 启动上报方式

默认初始化后会自动发送启动事件：

```dart
await signals.initialize();
```

如果业务需要手动控制启动事件上报，可关闭自动上报：

```dart
await signals.initialize(
  config: const JlSignalsConfig(
    autoSendLaunchEvent: false,
  ),
);

await signals.sendLaunchEvent();
```

## 6. Deeplink 处理

iOS 侧插件会自动监听 `AppDelegate` 的 `openURL` 回调，并将完整 URL 传给巨量引擎转化 SDK。宿主 App 仍需按巨量引擎要求配置 URL Scheme，推荐使用应用包名作为 scheme。

如果业务使用自定义 `SceneDelegate`，或已经在 Dart 层通过其他 deeplink 插件拿到了 URL，也可以手动将完整 URL 传给插件：

```dart
await signals.handleDeeplink(
  'com.example.app://oceanengine/ads?clickid=xxx&track_id=xxx',
);
```

获取 SDK 当前缓存的 clickid：

```dart
final clickId = await signals.getClickId();
```

## 7. 事件上报

注册、付费等关键事件可通过 `trackEvent` 上报：

```dart
await signals.trackEvent(
  'register',
  params: <String, Object?>{
    'method': 'phone',
  },
);

await signals.trackEvent(
  'purchase',
  params: <String, Object?>{
    'pay_amount': 2334,
  },
);
```

iOS 如需开启支付事件监听：

```dart
await signals.enablePurchaseEvent();
```

## 8. 设备标识

请在用户同意隐私政策后读取设备标识。

```dart
final deviceId = await JlSignalDeviceIds.getDeviceId();
final idfv = await JlSignalDeviceIds.getIdfv();
final androidId = await JlSignalDeviceIds.getAndroidId();
final oaid = await JlSignalDeviceIds.getOaid();
```

返回规则：

- `getDeviceId()`：iOS 返回 IDFV，Android 返回 Android ID，其他平台返回 `null`。
- `getIdfv()`：仅 iOS 返回 IDFV，其他平台返回 `null`。
- `getAndroidId()`：仅 Android 返回 Android ID，其他平台返回 `null`。
- `getOaid()`：仅 Android 返回 OAID；如果宿主未接入 OAID SDK、设备不支持、读取受限或当前平台不是 Android，则返回 `null`。

## 9. 配置参数

`JlSignalsConfig` 支持以下参数：

| 参数 | 平台 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `autoSendLaunchEvent` | Android | `true` | 初始化后是否自动发送启动事件 |
| `enableLog` | Android | `false` | 是否开启 SDK debug 日志 |
| `playSessionEnable` | Android | `true` | 是否启用心跳事件 |
| `enableOaid` | Android | `true` | SDK 是否采集 OAID |
| `customOaid` | Android | `null` | 业务自定义 OAID；传入后 SDK 自身不再采集 OAID |
| `customAndroidId` | Android | `null` | 业务自定义 Android ID |
| `optionalData` | iOS | `{}` | 注入 SDK 的额外参数 |
| `enableIdfa` | iOS | `false` | 是否允许 SDK 获取 IDFA |

## 10. API 列表

`JlSignals`：

- `initialize({JlSignalsConfig config})`
- `requestTrackingAuthorization()`
- `enableIdfa(bool enabled)`
- `handleDeeplink(String url)`
- `getClickId()`
- `registerOptionalData(Map<String, Object?> data)`
- `trackEvent(String name, {Map<String, Object?>? params})`
- `enablePurchaseEvent()`
- `sendLaunchEvent()`

`JlSignalDeviceIds`：

- `getDeviceId()`
- `getIdfv()`
- `getAndroidId()`
- `getOaid()`

## 11. 接入注意事项

- 采集设备信息、初始化 SDK、读取设备标识前，必须先获得用户对隐私政策的同意。
- `getOaid()` 会优先返回 `customOaid`；未传入时会尝试读取宿主 App 已接入的 MSA OAID SDK，未接入时返回 `null`。
- 如使用 IDFA，必须先完成 iOS ATT 授权流程，并按 App Store 要求声明追踪用途。
- `customOaid`、`customAndroidId` 必须传入真实且合规的业务值，错误值会影响归因。
- 服务端归因接口、转化回传、归因优先级比较由业务服务端处理，不在本插件内完成。
