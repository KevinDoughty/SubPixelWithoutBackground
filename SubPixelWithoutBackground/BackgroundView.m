//
//  BackgroundView.m
//  SubPixelWithoutBackground
//
//  Created by Kevin Doughty on 3/12/14.
//  Copyright (c) 2014 Kevin Doughty. All rights reserved.
//

#import "BackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@interface BackgroundView()
@property (assign) CALayer *lineMark;
@end

@implementation BackgroundView

-(void) awakeFromNib {
    self.wantsLayer = YES;
    CALayer *theLayer = [CALayer layer];
    theLayer.bounds = NSMakeRect(0,0,1000,1);
    theLayer.anchorPoint = CGPointZero;
    theLayer.position = CGPointZero;
    theLayer.backgroundColor = [[NSColor whiteColor] CGColor];
    theLayer.zPosition = -1;
    [self.layer addSublayer:theLayer];
    self.lineMark = theLayer;
}

-(void) mouseDown:(NSEvent*)theEvent {
	[self moveLine:theEvent];
    [self debugLayerHierarchy];
}

-(void) mouseDragged:(NSEvent*)theEvent {
	[self moveLine:theEvent];
}

-(void)moveLine:(NSEvent*)theEvent {
    CGPoint sanePoint = [self sanePointFromEvent:theEvent];
	[CATransaction begin];
    [CATransaction setDisableActions:YES];
    sanePoint.x = 0;
	self.lineMark.position = sanePoint;
    [CATransaction commit];
}

-(CGPoint) sanePointFromEvent:(NSEvent*)theEvent {
	return [self sanePointFromWindow:theEvent.locationInWindow];
}

-(CGPoint) sanePointFromWindow:(NSPoint)windowLoc {
	NSPoint viewLoc = [self convertPoint:windowLoc fromView:nil];
	NSPoint baseLoc = [self convertPointToBacking:viewLoc];
    CGPoint where = NSPointToCGPoint(baseLoc);
	return where;
}

-(BOOL)isOpaque {
    return YES;
}

-(BOOL)isFlipped {
    return NO;
}

-(BOOL)wantsUpdateLayer {
    return NO;
}

-(void)drawRect:(NSRect)theRect {
    //NSGradient *theGradient = [[NSGradient alloc] initWithStartingColor:[NSColor whiteColor] endingColor:[NSColor grayColor]];
    //NSGradient *theGradient = [[NSGradient alloc] initWithStartingColor:[NSColor yellowColor] endingColor:[NSColor blueColor]];
    //[theGradient drawInRect:self.bounds angle:270];
    
    NSColor *theColor = [NSColor windowBackgroundColor];
    //NSColor *theColor = [NSColor whiteColor];
    //NSColor *theColor = [NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1];
    //NSColor *theColor = [NSColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1];
    //NSColor *theColor = [NSColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1];
    //NSColor *theColor = [NSColor colorWithRed:.25 green:.5 blue:.75 alpha:1];
    [theColor set];
    [NSBezierPath fillRect:theRect];
}

-(void)debugLayerHierarchy {
    NSLog(@"-------");
    NSArray *theSubviews = self.subviews;
    for (NSControl *theView in theSubviews) {
        if ([theView isKindOfClass:[NSControl class]]) {
            NSControl *theControl = (NSControl*)theView;
            CALayer *theLayer = theControl.layer;
            NSArray *theSublayers = theLayer.sublayers;
            NSLog(@"control:%@; cell:%@; layer:%@; mask:%@; sublayers:%@;",theControl,theControl.cell,theLayer,theLayer.mask, theSublayers);
            for (CALayer *theSublayer in theSublayers) { // @[<NSTextLayer: 0x6000000937e0>]
                if ([theSublayer isKindOfClass:NSClassFromString(@"NSTextLayer")]) {
                    NSArray *theSubSublayers = theSublayer.sublayers;
                    NSLog(@"textlayer mask:%@; sublayers:%@;",theSublayer.mask,theSubSublayers); // @[<_NSLinearMaskBackingLayer: 0x6000000329a0>]
                    for (CALayer *theSubSublayer in theSubSublayers) {
                        NSLog(@"textlayer sublayer mask:%@; sublayers:%@;",theSubSublayer.mask,theSubSublayer.sublayers);
                    }
                }
            }
        }
    }
}

@end
