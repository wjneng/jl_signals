## 0.0.3

* Updated iOS deeplink clickid handling to call the public BDASignalManager APIs directly.
* Added iOS AppDelegate openURL forwarding so deeplink URLs are passed to the conversion SDK automatically.

## 0.0.2

* Added OAID getter API for Android.
* Kept Android ID and OAID collection aligned with the plugin config and native SDK availability.

## 0.0.1

* Initial release.
* Added Flutter APIs for initializing the Ocean Engine conversion signal SDK.
* Added deeplink clickid handling and cached clickid retrieval.
* Added event tracking and launch event reporting APIs.
* Added device identifier helpers for IDFV, Android ID, and OAID.
* Added Android and iOS native plugin implementations.
