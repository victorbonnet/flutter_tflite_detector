#import "FlutterTfliteDetectorPlugin.h"

@implementation FlutterTfliteDetectorPlugin

NSObject<FlutterPluginRegistrar>* registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)reg {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_tflite_detector"
            binaryMessenger:[reg messenger]];
    
    registrar = reg;
    FlutterTfliteDetectorPlugin* instance = [[FlutterTfliteDetectorPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"createDetector" isEqualToString:call.method]) {
      NSString *modelFileParam = call.arguments[@"modelFile"];
      if ([self stringIsNilOrEmpty:modelFileParam]) {
          result([FlutterError errorWithCode:@"0"
                                     message:@"Missing parameter"
                                     details:@"modelFile parameter is missing"]);
          return;
      }
      
      NSString *labelsFileParam = call.arguments[@"labelsFile"];
      if ([self stringIsNilOrEmpty:labelsFileParam]) {
          result([FlutterError errorWithCode:@"0"
                                     message:@"Missing parameter"
                                     details:@"labelFile parameter is missing"]);
          return;
      }
      
      NSString *inputSizeParam = call.arguments[@"inputSize"];
      if ([self stringIsNilOrEmpty:inputSizeParam]) {
          result([FlutterError errorWithCode:@"0"
                                     message:@"Missing parameter"
                                     details:@"inputSize parameter is missing"]);
          return;
      }
      
      NSString *isQuantizedParam = call.arguments[@"isQuantized"];
      if ([self stringIsNilOrEmpty:isQuantizedParam]) {
          result([FlutterError errorWithCode:@"0"
                                     message:@"Missing parameter"
                                     details:@"isQuantized parameter is missing"]);
          return;
      }
      
      NSString* assetModelKey = [registrar lookupKeyForAsset:modelFileParam];
      NSString* assetLabelsKey = [registrar lookupKeyForAsset:labelsFileParam];
      int inputSize = (int)inputSizeParam;
      bool isQuantized = (bool)isQuantizedParam;
      
      //todo to implement
      
      
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"closeDetector" isEqualToString:call.method]) {
    result(FlutterMethodNotImplemented);
  } else if ([@"closeDetector" isEqualToString:call.method]) {
    result(FlutterMethodNotImplemented);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !aString || [[aString  stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]] length] == 0;
}

@end
