#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSMutableDictionary<NSString *, NSString *> *fontMap;
void patchFonts(NSDictionary<NSString *, NSString *> *mainFonts,
                NSString *fontDefName);