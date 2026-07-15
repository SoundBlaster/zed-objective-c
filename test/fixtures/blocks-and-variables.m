#import <Foundation/Foundation.h>

typedef void (^ZEDCompletionBlock)(NSString *result, NSError *error);

static NSInteger ZEDStaticCounter = 0;

@interface ZEDBlockOwner : NSObject {
@private
    NSInteger _instanceCounter;
}

- (void)performWithCompletion:(ZEDCompletionBlock)completion;

@end

@implementation ZEDBlockOwner

- (void)performWithCompletion:(ZEDCompletionBlock)completion
{
    __block NSInteger mutableTotal = ZEDStaticCounter;
    NSInteger capturedIncrement = 1;

    void (^localBlock)(NSInteger) = ^(NSInteger amount) {
        mutableTotal += amount + capturedIncrement;
        _instanceCounter = mutableTotal;
    };

    localBlock(capturedIncrement);

    if (completion != nil) {
        completion(@"done", nil);
    }
}

@end
