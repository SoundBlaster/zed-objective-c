#import <Foundation/Foundation.h>

@protocol ZEDReadable <NSObject>

- (NSData *)readData;

@end

@protocol ZEDWritable

- (void)writeData:(NSData *)data;

@end

@protocol ZEDReadWrite <ZEDReadable, ZEDWritable>
@end

@interface ZEDDocument : NSObject <ZEDReadWrite>

@property(nonatomic, weak) id<ZEDReadable, ZEDWritable> delegate;

@end

@interface ZEDDocument (Diagnostics) <ZEDReadable>

- (NSString *)diagnosticSummary;

@end

@implementation ZEDDocument (Diagnostics)

- (NSString *)diagnosticSummary
{
    return @"ready";
}

@end

@interface ZEDDocument ()

@property(nonatomic, assign) NSUInteger internalRevision;

@end
