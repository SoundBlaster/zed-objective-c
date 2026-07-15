#import <Foundation/Foundation.h>

@protocol ZEDGreeter <NSObject>

- (NSString *)greetingForName:(NSString *)name;

@end

@interface ZEDPerson : NSObject <ZEDGreeter>

@property(nonatomic, copy, nullable) NSString *name;

- (instancetype)initWithName:(NSString *)name;

@end


@implementation ZEDPerson

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

- (NSString *)greetingForName:(NSString *)name
{
    return [NSString stringWithFormat:@"Hello, %@!", name];
}

@end
