//
//  TOCAssetCatalogBackgroundButtonTarget.m
//  TOCAssetCatalogBackground
//
//  Created by Tobias Conradi on 17.05.15.
//  Copyright (c) 2015 Tobias Conradi. Licensed under the MIT license.
//

#import "TOCAssetCatalogBackgroundButtonTarget.h"

static NSColor *TOCAssetCatalogSharedBackgroundColor = nil;
static NSString *TOCAssetCatalogBackgroundColorChanged = @"TOCAssetCatalogBackgroundColorChanged";

@implementation TOCAssetCatalogBackgroundButtonTarget

- (instancetype)init
{
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackgroundColor) name:TOCAssetCatalogBackgroundColorChanged object:nil];
	}
	return self;
}

- (void)updateBackgroundColor
{
	if (TOCAssetCatalogSharedBackgroundColor) {
		self.scrollView.backgroundColor = TOCAssetCatalogSharedBackgroundColor;
	}
}

- (void)segmentedControlChanged:(id)sender
{
	NSColor *currentColor = self.scrollView.backgroundColor;
	NSColor *nextColor = nil;
	if ([currentColor isEqualTo:[NSColor whiteColor]]) {
		nextColor = [NSColor colorWithWhite:0.1 alpha:1.0];
	} else {
		nextColor = [NSColor whiteColor];
	}
	TOCAssetCatalogSharedBackgroundColor = nextColor;
	[[NSNotificationCenter defaultCenter] postNotificationName:TOCAssetCatalogBackgroundColorChanged object:self];
	self.scrollView.backgroundColor = nextColor;
}

@end
