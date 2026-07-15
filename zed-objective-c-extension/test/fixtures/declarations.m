#import <Foundation/Foundation.h>

@class ZEDForwardDeclaration;

/** Supplies values to a widget. */
@protocol ZEDWidgetDataSource <NSObject>

@required
- (NSInteger)widget:(id)widget
    numberOfRowsInSection:(NSInteger)section;

@optional
@property(nonatomic, readonly, nullable) NSString *displayName;

@end

@interface ZEDWidget<ObjectType> : NSObject <ZEDWidgetDataSource>

@property(nonatomic, copy, nullable) ObjectType value;
@property(nonatomic, assign, getter=isReady) BOOL ready;

+ (instancetype)widgetWithValue:(ObjectType)value;
- (void)updateValue:(ObjectType)value
    completion:(void (^ _Nullable)(BOOL success))completion;

@end

@interface ZEDWidget (Debugging)

- (NSString *)debugDescription;

@end
