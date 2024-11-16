#import "Logger.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>

#define DISCORD_BUNDLE_ID @"com.hammerandchisel.discord"
#define DISCORD_NAME @"Discord"

static NSString *getAccessGroupID(void) {
  NSDictionary *query = @{
    (__bridge NSString *)
    kSecClass : (__bridge NSString *)kSecClassGenericPassword,
    (__bridge NSString *)kSecAttrAccount : @"bundleSeedID",
    (__bridge NSString *)kSecAttrService : @"",
    (__bridge NSString *)kSecReturnAttributes : @YES
  };

  CFDictionaryRef result = NULL;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                        (CFTypeRef *)&result);

  if (status == errSecItemNotFound) {
    status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  }

  if (status != errSecSuccess)
    return nil;

  NSString *accessGroup = [(__bridge NSDictionary *)result
      objectForKey:(__bridge NSString *)kSecAttrAccessGroup];
  if (result)
    CFRelease(result);

  return accessGroup;
}

static BOOL isSelfCall(void) {
  NSArray *address = [NSThread callStackReturnAddresses];
  Dl_info info = {0};
  if (dladdr((void *)[address[2] longLongValue], &info) == 0)
    return NO;
  NSString *path = [NSString stringWithUTF8String:info.dli_fname];
  return [path hasPrefix:NSBundle.mainBundle.bundlePath];
}

%group Sideloading

%hook NSBundle
- (NSString *)bundleIdentifier {
  return isSelfCall() ? DISCORD_BUNDLE_ID : %orig;
}

- (NSDictionary *)infoDictionary {
  if (!isSelfCall())
    return %orig;

  NSMutableDictionary *info = [%orig mutableCopy];
  info[@"CFBundleIdentifier"] = DISCORD_BUNDLE_ID;
  info[@"CFBundleDisplayName"] = DISCORD_NAME;
  info[@"CFBundleName"] = DISCORD_NAME;
  return info;
}

- (id)objectForInfoDictionaryKey:(NSString *)key {
  if (!isSelfCall())
    return %orig;

  if ([key isEqualToString:@"CFBundleIdentifier"])
    return DISCORD_BUNDLE_ID;
  if ([key isEqualToString:@"CFBundleDisplayName"] ||
      [key isEqualToString:@"CFBundleName"])
    return DISCORD_NAME;
  return %orig;
}
%end

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:
    (NSString *)groupIdentifier {
  BunnyLog(@"containerURLForSecurityApplicationGroupIdentifier called! %@",
           groupIdentifier ?: @"nil");

  NSArray *paths = [self URLsForDirectory:NSDocumentDirectory
                                inDomains:NSUserDomainMask];
  NSURL *lastPath = [paths lastObject];
  return [lastPath URLByAppendingPathComponent:@"AppGroup"];
}
%end

%hook UIPasteboard
- (NSString *)_accessGroup {
  return getAccessGroupID();
}
%end

%end

%ctor {
  BOOL isAppStoreApp = [[NSFileManager defaultManager]
      fileExistsAtPath:[[NSBundle mainBundle] appStoreReceiptURL].path];
  if (!isAppStoreApp)
    %init(Sideloading);
}
