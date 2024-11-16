#import "Utils.h"

NSURL *getPyoncordDirectory(void) {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *documentDirectoryURL =
      [[fileManager URLsForDirectory:NSDocumentDirectory
                           inDomains:NSUserDomainMask] lastObject];

  NSURL *pyoncordFolderURL =
      [documentDirectoryURL URLByAppendingPathComponent:@"pyoncord"];

  if (![fileManager fileExistsAtPath:pyoncordFolderURL.path]) {
    [fileManager createDirectoryAtURL:pyoncordFolderURL
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
  }

  return pyoncordFolderURL;
}

UIColor *hexToUIColor(NSString *hex) {
  if (![hex hasPrefix:@"#"]) {
    return nil;
  }

  NSString *hexColor = [hex substringFromIndex:1];
  if (hexColor.length == 6) {
    hexColor = [hexColor stringByAppendingString:@"ff"];
  }

  if (hexColor.length == 8) {
    unsigned int hexNumber;
    NSScanner *scanner = [NSScanner scannerWithString:hexColor];
    if ([scanner scanHexInt:&hexNumber]) {
      CGFloat r = ((hexNumber & 0xFF000000) >> 24) / 255.0;
      CGFloat g = ((hexNumber & 0x00FF0000) >> 16) / 255.0;
      CGFloat b = ((hexNumber & 0x0000FF00) >> 8) / 255.0;
      CGFloat a = (hexNumber & 0x000000FF) / 255.0;

      return [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
  }

  return nil;
}

void showErrorAlert(NSString *title, NSString *message) {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:title
                         message:message
                  preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction =
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil];

    [alert addAction:okAction];

    UIWindow *window = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *w in windows) {
      if (w.isKeyWindow) {
        window = w;
        break;
      }
    }

    [window.rootViewController presentViewController:alert
                                            animated:YES
                                          completion:nil];
  });
}