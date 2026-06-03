#import "JlSignalsPlugin.h"
#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#endif
#import <UIKit/UIKit.h>

static NSString *const JlSignalsErrorCode = @"jl_signals_error";

@implementation JlSignalsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"jl_signals"
            binaryMessenger:[registrar messenger]];
  JlSignalsPlugin* instance = [[JlSignalsPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  @try {
    if ([@"initialize" isEqualToString:call.method]) {
      [self initializeWithArguments:call.arguments];
      result(nil);
    } else if ([@"sendLaunchEvent" isEqualToString:call.method]) {
      [self sendLaunchEvent];
      result(nil);
    } else if ([@"enableIdfa" isEqualToString:call.method]) {
      [self enableIdfa:[self boolValue:call.arguments key:@"enabled" defaultValue:NO]];
      result(nil);
    } else if ([@"requestTrackingAuthorization" isEqualToString:call.method]) {
      [self requestTrackingAuthorizationWithResult:result];
    } else if ([@"handleDeeplink" isEqualToString:call.method]) {
      [self handleDeeplink:[self stringValue:call.arguments key:@"url"]];
      result(nil);
    } else if ([@"getClickId" isEqualToString:call.method]) {
      result([self getClickId]);
    } else if ([@"getIdfv" isEqualToString:call.method]) {
      result([self getIdfv]);
    } else if ([@"getAndroidId" isEqualToString:call.method]) {
      result(nil);
    } else if ([@"registerOptionalData" isEqualToString:call.method]) {
      [self registerOptionalData:[self dictionaryValue:call.arguments key:@"data"]];
      result(nil);
    } else if ([@"trackEvent" isEqualToString:call.method]) {
      [self trackEvent:[self stringValue:call.arguments key:@"name"]
                params:[self dictionaryValue:call.arguments key:@"params"]];
      result(nil);
    } else if ([@"enablePurchaseEvent" isEqualToString:call.method]) {
      [self enablePurchaseEvent];
      result(nil);
    } else {
      result(FlutterMethodNotImplemented);
    }
  } @catch (NSException *exception) {
    result([FlutterError errorWithCode:JlSignalsErrorCode
                               message:exception.reason
                               details:nil]);
  }
}

- (void)initializeWithArguments:(NSDictionary *)arguments {
  NSDictionary *config = [self dictionaryValue:arguments key:@"config"];
  NSDictionary *optionalData = [self dictionaryValue:config key:@"optionalData"];
  BOOL enableIdfa = [self boolValue:config key:@"enableIdfa" defaultValue:NO];

  [self enableIdfa:enableIdfa];
  [self registerOptionalData:optionalData];
  [self sendLaunchEvent];
}

- (void)sendLaunchEvent {
  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"didFinishLaunchingWithOptions:connectOptions:");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL, NSDictionary *, NSDictionary *) =
      (void (*)(id, SEL, NSDictionary *, NSDictionary *))[managerClass methodForSelector:selector];
  func(managerClass, selector, nil, nil);
}

- (void)enableIdfa:(BOOL)enabled {
  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"enableIdfa:");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL, BOOL) =
      (void (*)(id, SEL, BOOL))[managerClass methodForSelector:selector];
  func(managerClass, selector, enabled);
}

- (void)requestTrackingAuthorizationWithResult:(FlutterResult)result {
#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
  if (@available(iOS 14.0, *)) {
    [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
      dispatch_async(dispatch_get_main_queue(), ^{
        result([self trackingAuthorizationStatusName:status]);
      });
    }];
    return;
  }
#endif
  result(@"unsupported");
}

#if __has_include(<AppTrackingTransparency/AppTrackingTransparency.h>)
- (NSString *)trackingAuthorizationStatusName:(ATTrackingManagerAuthorizationStatus)status API_AVAILABLE(ios(14.0)) {
  switch (status) {
    case ATTrackingManagerAuthorizationStatusRestricted:
      return @"restricted";
    case ATTrackingManagerAuthorizationStatusDenied:
      return @"denied";
    case ATTrackingManagerAuthorizationStatusAuthorized:
      return @"authorized";
    case ATTrackingManagerAuthorizationStatusNotDetermined:
    default:
      return @"notDetermined";
  }
}
#endif

- (void)handleDeeplink:(NSString *)url {
  if (url.length == 0) {
    return;
  }

  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"anylyseDeeplinkClickidWithOpenUrl:");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL, NSString *) =
      (void (*)(id, SEL, NSString *))[managerClass methodForSelector:selector];
  func(managerClass, selector, url);
}

- (NSString *)getClickId {
  NSArray<NSString *> *classNames = @[@"BDASignalSDK", @"BDASignalManager"];
  NSArray<NSString *> *selectors = @[@"getClickId", @"getClickID", @"getClickid", @"clickId"];

  for (NSString *className in classNames) {
    Class clazz = NSClassFromString(className);
    if (!clazz) {
      continue;
    }
    for (NSString *selectorName in selectors) {
      SEL selector = NSSelectorFromString(selectorName);
      if (![clazz respondsToSelector:selector]) {
        continue;
      }
      id (*func)(id, SEL) = (id (*)(id, SEL))[clazz methodForSelector:selector];
      id value = func(clazz, selector);
      return [value isKindOfClass:NSString.class] ? value : nil;
    }
  }
  return nil;
}

- (NSString *)getIdfv {
  return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

- (void)registerOptionalData:(NSDictionary *)data {
  if (data.count == 0) {
    return;
  }

  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"registerWithOptionalData:");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL, NSDictionary *) =
      (void (*)(id, SEL, NSDictionary *))[managerClass methodForSelector:selector];
  func(managerClass, selector, data);
}

- (void)trackEvent:(NSString *)name params:(NSDictionary *)params {
  if (name.length == 0) {
    [NSException raise:@"JlSignalsInvalidArgument" format:@"Event name cannot be empty."];
  }

  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"trackEssentialEventWithName:params:");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL, NSString *, NSDictionary *) =
      (void (*)(id, SEL, NSString *, NSDictionary *))[managerClass methodForSelector:selector];
  func(managerClass, selector, name, params ?: @{});
}

- (void)enablePurchaseEvent {
  Class managerClass = [self signalManagerClass];
  SEL selector = NSSelectorFromString(@"enablePurchaseEvent");
  if (![managerClass respondsToSelector:selector]) {
    [self throwMissingSelector:selector];
  }

  void (*func)(id, SEL) = (void (*)(id, SEL))[managerClass methodForSelector:selector];
  func(managerClass, selector);
}

- (Class)signalManagerClass {
  Class managerClass = NSClassFromString(@"BDASignalManager");
  if (!managerClass) {
    [NSException raise:@"JlSignalsMissingSdk"
                format:@"BDASignalManager was not found. Check BDASignalSDK pod installation."];
  }
  return managerClass;
}

- (void)throwMissingSelector:(SEL)selector {
  [NSException raise:@"JlSignalsMissingSelector"
              format:@"BDASignalManager does not respond to %@.", NSStringFromSelector(selector)];
}

- (BOOL)boolValue:(NSDictionary *)dictionary
             key:(NSString *)key
    defaultValue:(BOOL)defaultValue {
  id value = [dictionary isKindOfClass:NSDictionary.class] ? dictionary[key] : nil;
  return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : defaultValue;
}

- (NSString *)stringValue:(NSDictionary *)dictionary key:(NSString *)key {
  id value = [dictionary isKindOfClass:NSDictionary.class] ? dictionary[key] : nil;
  return [value isKindOfClass:NSString.class] ? value : nil;
}

- (NSDictionary *)dictionaryValue:(NSDictionary *)dictionary key:(NSString *)key {
  id value = [dictionary isKindOfClass:NSDictionary.class] ? dictionary[key] : nil;
  return [value isKindOfClass:NSDictionary.class] ? value : @{};
}

@end
