#import <Foundation/Foundation.h>
#import <VisionCamera/FrameProcessorPlugin.h>
#import <VisionCamera/FrameProcessorPluginRegistry.h>
#import <VisionCamera/Frame.h>

#if __has_include("vision_camera_ocr/vision_camera_ocr-Swift.h")
#import "vision_camera_ocr/vision_camera_ocr-Swift.h"
#else
#import "vision_camera_ocr-Swift.h"
#endif

@interface OCRFrameProcessorPlugin (FrameProcessorPluginLoader)
@end

@implementation OCRFrameProcessorPlugin (FrameProcessorPluginLoader)
+ (void) load {
  [FrameProcessorPluginRegistry addFrameProcessorPlugin:@"scanOCR"
    withInitializer:^FrameProcessorPlugin*(VisionCameraProxyHolder* proxy, NSDictionary* options) {
    return [[OCRFrameProcessorPlugin alloc] initWithProxy:proxy withOptions:options];
  }];
}
@end
