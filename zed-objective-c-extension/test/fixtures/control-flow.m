#import <Foundation/Foundation.h>

void ZEDPerformWork(id lock, NSArray *items)
{
    @autoreleasepool {
        @synchronized (lock) {
            @try {
                for (id item in items) {
                    NSLog(@"%@", item);
                }
            } @catch (NSException *exception) {
                @throw exception;
            } @finally {
                NSLog(@"finished");
            }
        }
    }
}
