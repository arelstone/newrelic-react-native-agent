#import "NRMModularAgent.h"
#import <NewRelic/NewRelic.h>


@interface NewRelic (Private)
+ (bool) isAgentStarted:(SEL _Nonnull)callingMethod;
@end

@implementation NRMModularAgent

-(id)init {
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
    });
    return self;
}

+ (BOOL)requiresMainQueueSetup{
    return NO;
}

- (dispatch_queue_t)methodQueue{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

// Refer to https://facebook.github.io/react-native/docs/native-modules-ios for a list of supported argument types

RCT_EXPORT_METHOD(startAgent:(NSString* _Nonnull)appKey agentVersion:(NSString* _Nonnull) agentVersion reactNativeVersion:(NSString* _Nonnull) reactNativeVersion
                  config:(NSDictionary* _Nullable)agentConfig
                  startWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    NSLog(@"NRMA calling start agent for RN bridge is deprecated. The agent automatically starts on creation.");
    
    if([[agentConfig objectForKey:@"crashReportingEnabled"]boolValue] == NO) {
        [NewRelic disableFeatures:NRFeatureFlag_CrashReporting];
    }
    
     if ([[agentConfig objectForKey:@"networkRequestEnabled"]boolValue] == NO){
        [NewRelic disableFeatures:NRFeatureFlag_NetworkRequestEvents];
    }

     if ([[agentConfig objectForKey:@"networkErrorRequestEnabled"]boolValue] == NO){
        [NewRelic disableFeatures:NRFeatureFlag_RequestErrorEvents];
    }
    
    if([[agentConfig objectForKey:@"httpRequestBodyCaptureEnabled"]boolValue] == NO) {
        [NewRelic disableFeatures:NRFeatureFlag_HttpResponseBodyCapture];
    }
    if([[agentConfig objectForKey:@"webViewInstrumentationEnabled"]boolValue] == NO) {
        [NewRelic disableFeatures:NRFeatureFlag_WebViewInstrumentation];
    }
    
    if([[agentConfig objectForKey:@"interactionTracingEnabled"]boolValue] == NO) {
        [NewRelic disableFeatures:NRFeatureFlag_InteractionTracing];
    }
    
    [NewRelic setPlatform:(NRMAApplicationPlatform)NRMAPlatform_ReactNative];
    [NewRelic startWithApplicationToken: appKey];
    
    [NewRelic setAttribute:@"React Native Version" value:reactNativeVersion];
    
    resolve(@(TRUE));
}


RCT_EXPORT_METHOD(isAgentStarted:(NSString* _Nonnull)call
                  callback: (RCTResponseSenderBlock)callback){
    callback(@[[NSNull null], @(TRUE)]);
}

RCT_EXPORT_METHOD(recordBreadcrumb:(NSString* _Nonnull)eventName attributes:(NSDictionary* _Nullable)attributes) {
    [NewRelic recordBreadcrumb:eventName attributes:attributes];
}

RCT_EXPORT_METHOD(crashNow:(NSString* )message) {
    if([message length] == 0) {
        [NewRelic crashNow];
    } else {
        [NewRelic crashNow:message];
    }
}

RCT_EXPORT_METHOD(currentSessionId:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        NSString* sessionId = [NewRelic currentSessionId];
        resolve((NSString*)sessionId);
    } @catch (NSException *exception) {
        [NewRelic recordHandledException:exception];
        reject([exception name], [exception reason], nil);
    }
}

RCT_EXPORT_METHOD(noticeNetworkFailure:(NSString *)url
                  httpMethod:(NSString*)httpMethod
                  startTime:(double)startTime
                  endTime:(double)endTime
                  failure:(NSString* _Nonnull)failure) {
    NSURL *nsurl = [[NSURL alloc] initWithString:url];
    NSDictionary *dict = @{
        @"Unknown": [NSNumber numberWithInt:NRURLErrorUnknown],
        @"BadUrl": [NSNumber numberWithInt:NRURLErrorBadURL],
        @"TimedOut": [NSNumber numberWithInt:NRURLErrorTimedOut],
        @"CannotConnectToHost": [NSNumber numberWithInt:NRURLErrorCannotConnectToHost],
        @"DNSLookupFailed": [NSNumber numberWithInt:NRURLErrorDNSLookupFailed],
        @"BadServerResponse": [NSNumber numberWithInt:NRURLErrorBadServerResponse],
        @"SecureConnectionFailed": [NSNumber numberWithInt:NRURLErrorSecureConnectionFailed],
    };
    NSInteger iOSFailureCode = [[dict valueForKey:failure] integerValue];
    [NewRelic noticeNetworkFailureForURL:nsurl httpMethod:httpMethod startTime:startTime endTime:endTime andFailureCode:iOSFailureCode];
}

RCT_EXPORT_METHOD(recordMetric:(NSString*)name
                  category:(NSString *)category
                  value:(NSNumber* _Nonnull)value
                  countUnit:(NSString *)countUnit
                  valueUnit:(NSString *)valueUnit) {
    
    NSDictionary *dict = @{
        @"PERCENT": kNRMetricUnitPercent,
        @"BYTES": kNRMetricUnitBytes,
        @"SECONDS": kNRMetricUnitSeconds,
        @"BYTES_PER_SECOND": kNRMetricUnitsBytesPerSecond,
        @"OPERATIONS": kNRMetricUnitsOperations
    };
    if(value < 0) {
        [NewRelic recordMetricWithName:name category:category];
    } else {
        if(countUnit == nil || valueUnit == nil) {
            [NewRelic recordMetricWithName:name category:category value:value];
        } else {
            [NewRelic recordMetricWithName:name category:category value:value valueUnits:dict[valueUnit] countUnits:dict[countUnit]];
        }
    }

}

RCT_EXPORT_METHOD(removeAllAttributes) {
    [NewRelic removeAllAttributes];
}

RCT_EXPORT_METHOD(setMaxEventBufferTime:(NSNumber* _Nonnull)seconds) {
    unsigned int uint_seconds = seconds.unsignedIntValue;
    [NewRelic setMaxEventBufferTime:uint_seconds];
}

RCT_EXPORT_METHOD(setMaxEventPoolSize:(NSNumber* _Nonnull)maxSize) {
    unsigned int uint_maxSize = maxSize.unsignedIntValue;
    [NewRelic setMaxEventPoolSize:uint_maxSize];
}

RCT_EXPORT_METHOD(setStringAttribute:(NSString* _Nonnull)key withString:(NSString* _Nonnull)value) {
    [NewRelic setAttribute:key value:value];
}

RCT_EXPORT_METHOD(setNumberAttribute:(NSString* _Nonnull)key withNumber:( NSNumber* _Nonnull)value) {
    [NewRelic setAttribute:key value:value];
}

RCT_EXPORT_METHOD(setBoolAttribute:(NSString* _Nonnull)key withBool:value) {
    [NewRelic setAttribute:key value:value];
}

RCT_EXPORT_METHOD(removeAttribute:(NSString *)name)
{
    [NewRelic removeAttribute:(NSString * _Nonnull)name];
}

RCT_EXPORT_METHOD(incrementAttribute:(NSString *)key withNumber:(NSNumber* _Nonnull)value) {
    [NewRelic incrementAttribute:key value:value];
}


RCT_EXPORT_METHOD(setUserId:(NSString* _Nonnull)userId) {
    [NewRelic setUserId:userId];
}

//RCT_EXPORT_METHOD(continueSession) {
//    [NewRelic continueSession];
//}

RCT_EXPORT_METHOD(setJSAppVersion:(NSString* _Nonnull)version) {
    [NewRelic setAttribute:@"JSBundleId" value:version];
}


RCT_EXPORT_METHOD(recordCustomEvent:(NSString* _Nonnull) eventType eventName:(NSString* _Nullable)eventName eventAttributes:(NSDictionary* _Nullable)attributes) {
    // todo: Not sure if we need to check the validity of these arguments at all..
    [NewRelic recordCustomEvent:eventType name:eventName attributes:attributes];
}

/**
 * Track a method as an interaction
 */
RCT_EXPORT_METHOD(startInteraction:(NSString *)interactionName
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    @try {
        NSString* interactionId = [NewRelic startInteractionWithName:(NSString * _Null_unspecified)interactionName];
        resolve((NSString *)interactionId);
    } @catch (NSException *exception) {
        [NewRelic recordHandledException:exception];
        reject([exception name], [exception reason], nil);
    }
}

/**
 * End an interaction
 * Required. The string ID for the interaction you want to end.
 * This string is returned when you use startInteraction().
 */
RCT_EXPORT_METHOD(endInteraction:(NSString *)interactionId)
{
    [NewRelic stopCurrentInteraction:(NSString * _Null_unspecified)interactionId];
}


RCT_EXPORT_METHOD(nativeLog:(NSString* _Nonnull) name message:(NSString* _Nonnull) message) {
    NSDictionary *logs =  @{@"Name":name,@"Message": message};
    [NewRelic recordBreadcrumb:@"Console Events" attributes:logs];
    [NewRelic recordCustomEvent:@"Console Events" attributes:logs];
}

RCT_EXPORT_METHOD(recordStack:(NSString* _Nullable) errorName
                  errorMessage:(NSString* _Nullable)errorMessage
                  errorStack:(NSString* _Nullable)errorStack
                  isFatal:(NSNumber* _Nonnull)isFatal
                  jsAppVersion:(NSString* _Nullable)jsAppVersion) {
    
    //Errorstack length may be more that attribute length limit 4096.
    NSRange needleRange = NSMakeRange(0,3994);
    NSString *error = [errorStack substringWithRange:needleRange];
    NSDictionary *dict =  @{@"Name":errorName,@"Message": errorMessage,@"isFatal": isFatal,@"jsAppVersion": jsAppVersion,@"errorStack": error};
    [NewRelic recordBreadcrumb:@"JS Errors" attributes:dict];
    [NewRelic recordCustomEvent:@"JS Errors" attributes:dict];
}

@end

