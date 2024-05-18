#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(AudioSync, NSObject)

RCT_EXTERN_METHOD(calculateSyncOffset:(NSString)audioFile1Path audioFile2Path:(NSString)audioFile2Path
                  withResolver: (RCTPromiseResolveBlock)resolve
                  withRejecter: (RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
