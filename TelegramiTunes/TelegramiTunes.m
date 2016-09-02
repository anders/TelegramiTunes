// cc -o TelegramiTunes.dylib -dynamiclib TelegramiTunes.m  -framework Cocoa
// env DYLD_INSERT_LIBRARIES=/Users/anders/TelegramiTunes.dylib \
//   /Applications/Telegram.app/Contents/MacOS/Telegram

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static NSString *lastKnownTrack = nil;
static void (*originalIMP)(id, SEL, NSString *, id, void *a, void *b, void *c) = NULL;

static void override_sendMessage(id self, SEL _cmd, NSString *message,
                                 id conversation, void *a, void *b, void *c) {
  if ([message rangeOfString:@"%_itunes" options:NSCaseInsensitiveSearch]
          .location != NSNotFound) {
    if (lastKnownTrack) {
      message = [message
          stringByReplacingOccurrencesOfString:@"%_itunes"
                                    withString:lastKnownTrack
                                       options:NSCaseInsensitiveSearch
                                         range:NSMakeRange(0, [message length])];
    }
  }

  originalIMP(self, _cmd, message, conversation, a, b, c);
}

@interface TelegramiTunes : NSObject
- (void)updateTrackInfo:(NSNotification *)notification;
@end

@implementation TelegramiTunes

- (void)updateTrackInfo:(NSNotification *)notification {
  NSDictionary *dict = [notification userInfo];

  NSString *artist = dict[@"Artist"];
  NSString *name = dict[@"Name"];
  if (!artist || !name) {
    return;
  }

  if (lastKnownTrack) {
    [lastKnownTrack release];
    lastKnownTrack = nil;
  }

  lastKnownTrack = [NSString stringWithFormat:@"%@ - %@", artist, name];
  [lastKnownTrack retain];
}
//- (void)sendMessage:(id)arg1 forConversation:(id)arg2 entities:(id)arg3 nowebpage:(BOOL)arg4 callback:(CDUnknownBlockType)arg5;

+ (void)load {
  Class targetClass = NSClassFromString(@"MessagesViewController");
  Method targetMethod = class_getInstanceMethod(
      targetClass, @selector(sendMessage:forConversation:entities:nowebpage:callback:));
  originalIMP = (void *)method_getImplementation(targetMethod);

  if (!class_addMethod(
          targetClass, @selector(sendMessage:forConversation:entities:nowebpage:callback:),
          (IMP)override_sendMessage, method_getTypeEncoding(targetMethod))) {
    method_setImplementation(targetMethod, (IMP)override_sendMessage);
  }

  TelegramiTunes *tgi = [[TelegramiTunes alloc] init];

  NSDistributedNotificationCenter *dnc =
      [NSDistributedNotificationCenter defaultCenter];
  [dnc addObserver:tgi
          selector:@selector(updateTrackInfo:)
              name:@"com.apple.iTunes.playerInfo"
            object:nil];
  NSLog(@"TelegramiTunes loaded and set up!");
}

@end