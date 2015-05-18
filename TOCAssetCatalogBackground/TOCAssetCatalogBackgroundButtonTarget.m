//
//  TOCAssetCatalogBackgroundButtonTarget.m
//  TOCAssetCatalogBackground
//
//  Created by Tobias Conradi on 17.05.15.
//  Copyright (c) 2015 Tobias Conradi. Licensed under the MIT license.
//

#import "TOCAssetCatalogBackgroundButtonTarget.h"

NSString *const TOCAssetCatalogBackgroundColorChangedNotification = @"TOCAssetCatalogBackgroundColorChanged";
TOCAssetCatalogBackgroundType TOCAssetCatalogBackgroundCurrentBackgroundType = TOCAssetCatalogBackgroundTypeLightBackground;

@implementation TOCAssetCatalogBackgroundButtonTarget

- (instancetype)init
{
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBackgroundColor) name:TOCAssetCatalogBackgroundColorChangedNotification object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateBackgroundColor
{
	NSColor *nextColor = nil;
	switch (TOCAssetCatalogBackgroundCurrentBackgroundType) {
		case TOCAssetCatalogBackgroundTypeDarkBackground:
			nextColor = [NSColor colorWithWhite:0.1 alpha:1.0];
			break;
		case TOCAssetCatalogBackgroundTypeLightBackground:
		default:
			nextColor = [NSColor whiteColor];
	}
	self.scrollView.backgroundColor = nextColor;
}

- (void)segmentedControlChanged:(id)sender
{
	switch (TOCAssetCatalogBackgroundCurrentBackgroundType) {
		case TOCAssetCatalogBackgroundTypeDarkBackground:
			TOCAssetCatalogBackgroundCurrentBackgroundType = TOCAssetCatalogBackgroundTypeLightBackground;
			break;
		case TOCAssetCatalogBackgroundTypeLightBackground:
		default:
			TOCAssetCatalogBackgroundCurrentBackgroundType = TOCAssetCatalogBackgroundTypeDarkBackground;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:TOCAssetCatalogBackgroundColorChangedNotification object:self];
}

@end
