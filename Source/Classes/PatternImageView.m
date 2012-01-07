//
//  PatternImageView.m
//  AzPackList
//
//  Created by Sum Positive on 12/01/07.
//  Copyright (c) 2012 Azukid. All rights reserved.
//

#import "PatternImageView.h"

@implementation PatternImageView
{
@private
    UIImage		*image_;
}


- (id)initWithFrame:(CGRect)frame  patternImage:(UIImage*)image 
{
	self = [super init];
	if (self) {
		self.frame = frame;
		image_ = image;
	}
	return self;
}

- (void)drawRect:(CGRect)rect 
{
	[image_ drawAsPatternInRect:self.bounds];	// タイル描画
}

@end

