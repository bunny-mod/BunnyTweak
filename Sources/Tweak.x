#import "Fonts.h"
#import "LoaderConfig.h"
#import "Logger.h"
#import "Theme.h"
#import "Utils.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSURL *source;
static BOOL isJailbroken;
static NSString *bunnyPatchesBundlePath;
static NSURL *pyoncordDirectory;
static LoaderConfig *loaderConfig;

%hook RCTCxxBridge

- (void)executeApplicationScript:(NSData *)script
                             url:(NSURL *)url
                           async:(BOOL)async {
  if (![url.absoluteString containsString:@"main.jsbundle"]) {
    return %orig;
  }

  NSBundle *bunnyPatchesBundle =
      [NSBundle bundleWithPath:bunnyPatchesBundlePath];
  if (!bunnyPatchesBundle) {
    BunnyLog(@"Failed to load BunnyPatches bundle from path: %@",
             bunnyPatchesBundlePath);
    showErrorAlert(
        @"Loader Error",
        @"Failed to initialize mod loader. Please reinstall the tweak.");
    return %orig;
  }

  NSURL *patchPath = [bunnyPatchesBundle URLForResource:@"payload-base"
                                          withExtension:@"js"];
  if (!patchPath) {
    BunnyLog(@"Failed to find payload-base.js in bundle");
    showErrorAlert(
        @"Loader Error",
        @"Failed to initialize mod loader. Please reinstall the tweak.");
    return %orig;
  }

  NSData *patchData = [NSData dataWithContentsOfURL:patchPath];
  BunnyLog(@"Injecting loader");
  %orig(patchData, source, YES);

  __block NSData *bundle = [NSData
      dataWithContentsOfURL:[pyoncordDirectory
                                URLByAppendingPathComponent:@"bundle.js"]];

  dispatch_group_t group = dispatch_group_create();
  dispatch_group_enter(group);

  NSURL *bundleUrl;
  if (loaderConfig.customLoadUrlEnabled && loaderConfig.customLoadUrl) {
    bundleUrl = loaderConfig.customLoadUrl;
    BunnyLog(@"Using custom load URL: %@", bundleUrl.absoluteString);
  } else {
    bundleUrl = [NSURL URLWithString:@"https://raw.githubusercontent.com/"
                                     @"bunny-mod/builds/main/bunny.min.js"];
    BunnyLog(@"Using default bundle URL: %@", bundleUrl.absoluteString);
  }

  NSMutableURLRequest *bundleRequest = [NSMutableURLRequest
       requestWithURL:bundleUrl
          cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
      timeoutInterval:3.0];

  NSString *bundleEtag = [NSString
      stringWithContentsOfURL:[pyoncordDirectory
                                  URLByAppendingPathComponent:@"etag.txt"]
                     encoding:NSUTF8StringEncoding
                        error:nil];
  if (bundleEtag && bundle) {
    [bundleRequest setValue:bundleEtag forHTTPHeaderField:@"If-None-Match"];
  }

  NSURLSession *session =
      [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration
                                                 defaultSessionConfiguration]];
  [[session
      dataTaskWithRequest:bundleRequest
        completionHandler:^(NSData *data, NSURLResponse *response,
                            NSError *error) {
          if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
              bundle = data;
              [bundle writeToURL:[pyoncordDirectory
                                     URLByAppendingPathComponent:@"bundle.js"]
                      atomically:YES];

              NSString *etag =
                  [httpResponse.allHeaderFields objectForKey:@"Etag"];
              if (etag) {
                [etag writeToURL:[pyoncordDirectory
                                     URLByAppendingPathComponent:@"etag.txt"]
                      atomically:YES
                        encoding:NSUTF8StringEncoding
                           error:nil];
              }
            }
          }
          dispatch_group_leave(group);
        }] resume];

  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

  NSString *themeString = [NSString
      stringWithContentsOfURL:
          [pyoncordDirectory URLByAppendingPathComponent:@"current-theme.json"]
                     encoding:NSUTF8StringEncoding
                        error:nil];
  if (themeString) {
    NSString *jsCode =
        [NSString stringWithFormat:@"globalThis.__PYON_LOADER__.storedTheme=%@",
                                   themeString];
    %orig([jsCode dataUsingEncoding:NSUTF8StringEncoding], source,
                     async);
  }

  NSData *fontData = [NSData
      dataWithContentsOfURL:[pyoncordDirectory
                                URLByAppendingPathComponent:@"fonts.json"]];
  if (fontData) {
    NSError *jsonError;
    NSDictionary *fontDict =
        [NSJSONSerialization JSONObjectWithData:fontData
                                        options:0
                                          error:&jsonError];
    if (!jsonError && fontDict[@"main"]) {
      BunnyLog(@"Found font configuration, applying...");
      patchFonts(fontDict[@"main"], fontDict[@"name"]);
    }
  }

  if (bundle) {
    BunnyLog(@"Executing JS bundle");
    %orig(bundle, source, async);
  }

  NSURL *preloadsDirectory =
      [pyoncordDirectory URLByAppendingPathComponent:@"preloads"];
  if ([[NSFileManager defaultManager]
          fileExistsAtPath:preloadsDirectory.path]) {
    NSError *error = nil;
    NSArray *contents = [[NSFileManager defaultManager]
          contentsOfDirectoryAtURL:preloadsDirectory
        includingPropertiesForKeys:nil
                           options:0
                             error:&error];
    if (!error) {
      for (NSURL *fileURL in contents) {
        if ([[fileURL pathExtension] isEqualToString:@"js"]) {
          BunnyLog(@"Executing preload JS file %@", fileURL.absoluteString);
          NSData *data = [NSData dataWithContentsOfURL:fileURL];
          if (data) {
            %orig(data, source, async);
          }
        }
      }
    } else {
      BunnyLog(@"Error reading contents of preloads directory");
    }
  }

  %orig(script, url, async);
}

%end

%ctor {
  @autoreleasepool {
    source = [NSURL URLWithString:@"bunny"];

    NSString *install_prefix = @"/var/jb";
    isJailbroken =
        [[NSFileManager defaultManager] fileExistsAtPath:install_prefix];

    NSString *bundlePath =
        [NSString stringWithFormat:
                      @"%@/Library/Application Support/BunnyResources.bundle",
                      install_prefix];
    BunnyLog(@"Is jailbroken: %d", isJailbroken);
    BunnyLog(@"Bundle path for jailbroken: %@", bundlePath);

    NSString *jailedPath = [[NSBundle mainBundle].bundleURL.path
        stringByAppendingPathComponent:@"BunnyResources.bundle"];
    BunnyLog(@"Bundle path for jailed: %@", jailedPath);

    bunnyPatchesBundlePath = isJailbroken ? bundlePath : jailedPath;
    BunnyLog(@"Selected bundle path: %@", bunnyPatchesBundlePath);

    BOOL bundleExists = [[NSFileManager defaultManager]
        fileExistsAtPath:bunnyPatchesBundlePath];
    BunnyLog(@"Bundle exists at path: %d", bundleExists);

    NSError *error = nil;
    NSArray *bundleContents = [[NSFileManager defaultManager]
        contentsOfDirectoryAtPath:bunnyPatchesBundlePath
                            error:&error];
    if (error) {
      BunnyLog(@"Error listing bundle contents: %@", error);
    } else {
      BunnyLog(@"Bundle contents: %@", bundleContents);
    }

    pyoncordDirectory = getPyoncordDirectory();
    loaderConfig = [[LoaderConfig alloc] init];
    [loaderConfig loadConfig];

    %init;
  }
}
