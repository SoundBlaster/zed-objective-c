#import <Foundation/Foundation.h>

@interface ZEDExamples : NSObject

- (void)runExamples;

@end

@implementation ZEDExamples

- (void)runExamples
{
    NSArray<NSString *> *names = @[@"Ada", @"Grace"];
    NSDictionary<NSString *, NSNumber *> *scores = @{
        @"Ada": @1,
        @"Grace": @2,
    };

    SEL selector = @selector(objectAtIndexedSubscript:);
    const char *encoding = @encode(NSUInteger);
    BOOL enabled = YES;
    id missingValue = nil;

    [NSString stringWithFormat:@"%@ %@", names.firstObject, scores[@"Ada"]];
    [self performSelector:selector];

    void (^completion)(BOOL) = ^(BOOL success) {
        NSLog(@"completed: %@", success ? @"YES" : @"NO");
    };
    completion(enabled);

    (void)encoding;
    (void)missingValue;
}

@end
