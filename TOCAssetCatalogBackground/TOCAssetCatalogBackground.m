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
- (id)effectiveTitleColor;
- (void)refreshHighlightState;
@end

@interface TOCAssetCatalogBackground()

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic) BOOL hookedIBICAbstractCatalogDetailController;
@property (nonatomic) BOOL hookIBICMultipartImageView;

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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hookClasses) name:NSBundleDidLoadNotification object:nil];
		[self hookClasses];

    }
    return self;
}

// since official plugins might not be loaded when we try to hook the classes,
// we might need to wait for the bundles to load.
// therefore hookClasses gets called every time a bundle is loaded, so we keep state
// which class was hooked successfully.
- (void)hookClasses {
	if (!self.hookedIBICAbstractCatalogDetailController) {
		self.hookedIBICAbstractCatalogDetailController = [self hookIBICAbstractCatalogDetailController];
	}
	if (!self.hookIBICMultipartImageView) {
		self.hookIBICMultipartImageView = [self hookIBICMultipartImageView];
	}

	BOOL allHooked = self.hookedIBICAbstractCatalogDetailController && self.hookIBICMultipartImageView;
	if (allHooked) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSBundleDidLoadNotification object:nil];
	}
}

- (BOOL)hookIBICAbstractCatalogDetailController
{

	id catalogControllerClass = NSClassFromString(@"IBICAbstractCatalogDetailController");
	if (!catalogControllerClass) {
		return NO;
	}

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

	return YES;
}

- (void)abstractCatalogDetailControllerDidLoad:(NSViewController *)controller
{
	NSSegmentedControl *barButton = [NSClassFromString(@"IBAccessorizedScrollViewButtonBar") barButtonWithTitle:@"Change Background Color"];

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

- (BOOL)hookIBICMultipartImageView
{
	id multiPartImageViewClass = NSClassFromString(@"IBICMultipartImageView");
	if (!multiPartImageViewClass) {
		return NO;
	}
	NSError *error;

	void (^effectiveTitleColorBlock)(id<TOCAssetCatalogBackground_AspectInfo>) =
	^(id<TOCAssetCatalogBackground_AspectInfo> info){
		BOOL replaceColor = YES;
		id instance = [info instance];
		NSInvocation *invocation = [info originalInvocation];

		if (TOCAssetCatalogBackgroundCurrentBackgroundType != TOCAssetCatalogBackgroundTypeDarkBackground) {
			replaceColor = NO;
		}
		if ([[instance valueForKey:@"wholeSetShowsSelection"] boolValue]) {
			replaceColor = NO;
		}
		if (replaceColor) {
			__unsafe_unretained NSColor *color = [NSColor whiteColor];
			[invocation setReturnValue:(void *)&color];
		} else {
			[invocation invoke];
		}
	};

	[multiPartImageViewClass tocassetcatalogbackground_aspect_hookSelector:@selector(effectiveTitleColor)
															   withOptions:AspectPositionInstead
																usingBlock:effectiveTitleColorBlock
																	 error:&error];
	if (error != nil) {
		NSLog(@"Failed to hook -[IBICMultipartImageView effectiveTitleColor] with error: %@",error);
		error = nil;
	}


	void (^viewDidMoveToWindowBlock)(id<TOCAssetCatalogBackground_AspectInfo>) =
	^(id<TOCAssetCatalogBackground_AspectInfo> info){
		NSView *instance = [info instance];
		if (instance.window) {
			[[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(refreshHighlightState) name:TOCAssetCatalogBackgroundColorChangedNotification object:nil];
		} else {
			[[NSNotificationCenter defaultCenter] removeObserver:instance name:TOCAssetCatalogBackgroundColorChangedNotification object:nil];
		}
	};

	[multiPartImageViewClass tocassetcatalogbackground_aspect_hookSelector:@selector(viewDidMoveToWindow)
															   withOptions:AspectPositionAfter
																usingBlock:viewDidMoveToWindowBlock
																	 error:&error];
	if (error != nil) {
		NSLog(@"Failed to hook -[IBICMultipartImageView viewDidMoveToWindow] with error: %@",error);
	}
	return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
