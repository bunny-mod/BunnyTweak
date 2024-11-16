#import "Theme.h"
#import "Logger.h"
#import "Utils.h"
#import <objc/runtime.h>

void swizzleDCDThemeColor(
    NSDictionary<NSString *, NSArray<NSString *> *> *semanticColors) {
  BunnyLog(@"Swizzling DCDThemeColor");

  Class DCDTheme = NSClassFromString(@"DCDTheme");
  Class dcdThemeTarget = object_getClass(DCDTheme);

  SEL themeIndexSelector = NSSelectorFromString(@"themeIndex");
  Method themeIndexMethod =
      class_getClassMethod(dcdThemeTarget, themeIndexSelector);
  IMP themeIndexImpl = method_getImplementation(themeIndexMethod);
  int (*themeIndex)(id, SEL) = (int (*)(id, SEL))themeIndexImpl;

  Class DCDThemeColor = NSClassFromString(@"DCDThemeColor");
  Class target = object_getClass(DCDThemeColor);

  unsigned int methodCount;
  Method *methods = class_copyMethodList(target, &methodCount);

  for (unsigned int i = 0; i < methodCount; i++) {
    Method method = methods[i];
    SEL selector = method_getName(method);
    NSString *methodName = NSStringFromSelector(selector);

    NSArray<NSString *> *semanticColor = semanticColors[methodName];
    if (semanticColor) {
      BunnyLog(@"Swizzling %@", methodName);

      IMP originalImpl = method_getImplementation(method);
      UIColor *(*original)(id, SEL) = (UIColor * (*)(id, SEL)) originalImpl;

      id block = ^UIColor *(id self) {
        int themeIndexVal = themeIndex(dcdThemeTarget, themeIndexSelector);
        if (semanticColor.count - 1 >= themeIndexVal) {
          UIColor *semanticUIColor = hexToUIColor(semanticColor[themeIndexVal]);
          if (semanticUIColor) {
            return semanticUIColor;
          }
        }
        return original(target, selector);
      };

      IMP newImpl = imp_implementationWithBlock(block);
      method_setImplementation(method, newImpl);
    }
  }

  free(methods);
}

void swizzleUIColor(NSDictionary<NSString *, NSString *> *rawColors) {
  BunnyLog(@"Swizzling UIColor");

  Class UIColorClass = NSClassFromString(@"UIColor");
  Class target = object_getClass(UIColorClass);

  unsigned int methodCount;
  Method *methods = class_copyMethodList(target, &methodCount);

  for (unsigned int i = 0; i < methodCount; i++) {
    Method method = methods[i];
    SEL selector = method_getName(method);
    NSString *methodName = NSStringFromSelector(selector);

    NSString *rawColor = rawColors[methodName];
    if (rawColor) {
      BunnyLog(@"Swizzling %@", methodName);

      id block = ^UIColor *(id self) {
        return hexToUIColor(rawColor);
      };

      IMP newImpl = imp_implementationWithBlock(block);
      method_setImplementation(method, newImpl);
    }
  }

  free(methods);
}