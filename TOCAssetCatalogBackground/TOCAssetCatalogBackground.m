//
//  TOCAssetCatalogBackground.m
//  TOCAssetCatalogBackground
//
//  Created by Tobias Conradi on 17.05.15.
//  Copyright (c) 2015 Tobias Conradi. Licensed under the MIT license.
//

#import <objc/runtime.h>
#import "TOCAssetCatalogBackground.h"
#import "TOCAssetCatalogBackgroundButtonTarget.h"
#import "Aspects.h"

static TOCAssetCatalogBackground *sharedPlugin;

@interface NSObject (ShutUpWarnings)
+ (id)barButtonWithTitle:(id)arg1;
@end

@interface TOCAssetCatalogBackground()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, weak) NSScrollView *scrollView;
@end

@implementation TOCAssetCatalogBackground

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;

		id catalogControllerClass = NSClassFromString(@"IBICAbstractCatalogDetailController");
		NSError *error;
		[catalogControllerClass tocassetcatalogbackground_aspect_hookSelector:@selector(viewDidLoad)
										withOptions:AspectPositionAfter
										 usingBlock:^(id<TOCAssetCatalogBackground_AspectInfo> info) {
											 [self abstractCatalogDetailControllerDidLoad:(NSViewController *)info.instance];
										 }
											  error:&error];
		if (error != nil) {
			NSLog(@"Failed to hook -[IBICAbstractCatalogDetailController viewDidLoad] with error: %@",error);
		}
    }
    return self;
}

- (void)abstractCatalogDetailControllerDidLoad:(NSViewController *)controller
{
	NSSegmentedControl *barButton = [NSClassFromString(@"IBAccessorizedScrollViewButtonBar") barButtonWithTitle:@"Change Backgroundcolor"];

	NSScrollView *scrollView = [controller valueForKey:@"scrollView"];
	id buttonBar = [scrollView valueForKey:@"buttonBar"];

	NSMutableArray *buttonsArray = [[buttonBar valueForKey:@"rightViews"] mutableCopy];
	[buttonsArray insertObject:barButton atIndex:0];
	[buttonBar setValue:[buttonsArray copy] forKey:@"rightViews"];

	TOCAssetCatalogBackgroundButtonTarget *target = [TOCAssetCatalogBackgroundButtonTarget new];
	target.scrollView = scrollView;
	barButton.target = target;
	barButton.action = @selector(segmentedControlChanged:);
	[target updateBackgroundColor];

	const void *key = @selector(segmentedControlChanged:); // just need a key
	objc_setAssociatedObject(barButton,key, target, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
