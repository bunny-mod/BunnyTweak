@interface RCTCxxBridge : NSObject
- (void)executeApplicationScript:(NSData *)script
                             url:(NSURL *)url
                           async:(BOOL)async;
@end