//
//  ManualTextFieldCell.m
//  SubPixelWithoutBackground
//
//  Created by Kevin Doughty on 3/12/14.
//  Copyright (c) 2014 Kevin Doughty. All rights reserved.
//

#import "ManualTextFieldCell.h"

struct ManualPixel { uint8_t b, g, r, a; };
static NSTextView *manualTextDrawingObject = nil;

@interface ManualTextFieldCell()
@property (assign) BOOL isDrawingInterior;
@end


@implementation ManualTextFieldCell

+(NSTextView*) textDrawingObject {
    if (manualTextDrawingObject == nil) {
        NSWindow *theWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200) styleMask:0 backing:NSBackingStoreBuffered defer:NO];
        NSView *theContentView = [theWindow contentView];
        NSTextField *theTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
        [theContentView addSubview:theTextField];
        NSText *theTextObject = [theWindow fieldEditor:YES forObject:nil];
        NSTextFieldCell *theTextFieldCell = [theTextField cell];
        NSTextView *theTextView = (NSTextView*)theTextObject;
        [theTextFieldCell selectWithFrame:theTextField.bounds inView:theTextField editor:theTextObject delegate:nil start:0 length:0]; // thank you bavarious
        manualTextDrawingObject = theTextView; // I want ARC to destroy the window but keep this forever.
    }
    return manualTextDrawingObject;
}

-(NSTextView*)textDrawingObject {
    NSTextView *theTextView = [[self class] textDrawingObject];
    return theTextView;
}

-(void)drawInteriorWithFrame:(NSRect)theControlViewBounds inView:(NSView*)theControlView {
    if (!self.controlView.layer) {
        NSLog(@"%@ requires a layer backed view hierarchy.",self);
        [super drawInteriorWithFrame:theControlViewBounds inView:theControlView];
    } else if (!self.isDrawingInterior) { // must prevent cacheDisplayInRect:toBitmapImageRep: from calling drawInteriorWithFrame:inView:
        NSLog(@"%@ drawInteriorWithFrame:%@; inView:%@;",self, NSStringFromRect(theControlViewBounds),theControlView);
        self.isDrawingInterior = YES;
        NSTextView *theTextView = [self textDrawingObject];
        NSTextContainer *theTextContainer = [theTextView textContainer];
        NSLayoutManager *theLayoutManager = [theTextContainer layoutManager];
        NSTextStorage *theTextStorage = [theLayoutManager textStorage];
        NSRange theOldGlyphRange = NSMakeRange(0, [theLayoutManager numberOfGlyphs]);
        NSRange theOldCharacterRange = [theLayoutManager characterRangeForGlyphRange:theOldGlyphRange actualGlyphRange:nil];
        [self setUpFieldEditorAttributes:theTextView];
        
        [theTextStorage replaceCharactersInRange:theOldCharacterRange withAttributedString:[self attributedStringValue]];
        NSRect theCellFrame = [self titleRectForBounds:theControlViewBounds];
        [theTextView setFrame:theCellFrame];
        
        NSPoint theDrawPoint = theCellFrame.origin;
        NSRange theNewGlyphRange = NSMakeRange(0, [theLayoutManager numberOfGlyphs]);
        
        NSView *theOpaqueAncestor = self.controlView;
        NSView *theContentView = self.controlView.window.contentView;
        while (theOpaqueAncestor != theContentView.superview) {
            if (theOpaqueAncestor.isOpaque) {
                CGContextRef theCurrentContext = [[NSGraphicsContext currentContext] graphicsPort];
                NSRect controlRect = self.controlView.bounds;
                
                NSRect theAncestorRect = [self.controlView convertRect:controlRect toView:theOpaqueAncestor];
                CGSize theSize = theAncestorRect.size;
                
                NSBitmapImageRep *theAncestorRep = [theOpaqueAncestor bitmapImageRepForCachingDisplayInRect:theAncestorRect];
                [theOpaqueAncestor cacheDisplayInRect:theAncestorRect toBitmapImageRep:theAncestorRep];
                
                if (theOpaqueAncestor.isFlipped != self.controlView.isFlipped) {
                    NSAffineTransform *theTransform = [NSAffineTransform transform];
                    [theTransform scaleXBy:1.0 yBy:-1.0];
                    CGFloat theFlip = theAncestorRect.size.height;
                    [theTransform translateXBy:0.0 yBy:-theFlip];
                    [theTransform concat];
                }
                
                CGContextDrawImage(theCurrentContext, CGRectMake(0,0,theAncestorRect.size.width,theAncestorRect.size.height),[theAncestorRep CGImage]);
                
                if (theOpaqueAncestor.isFlipped != self.controlView.isFlipped) {
                    NSAffineTransform *theTransform = [NSAffineTransform transform];
                    [theTransform scaleXBy:1.0 yBy:-1.0];
                    CGFloat theFlip = theAncestorRect.size.height;
                    [theTransform translateXBy:0.0 yBy:-theFlip];
                    [theTransform concat];
                }
                
                CGContextSetShouldSmoothFonts(theCurrentContext,YES);
                CGContextSetAllowsAntialiasing(theCurrentContext,YES);
                CGContextSetAllowsFontSmoothing(theCurrentContext,YES);
                CGContextSetAllowsFontSubpixelPositioning(theCurrentContext,YES);
                CGContextSetAllowsFontSubpixelQuantization(theCurrentContext,YES);
                
                [theLayoutManager drawGlyphsForGlyphRange:theNewGlyphRange atPoint:theDrawPoint];
                
                struct ManualPixel *bothPixels = CGBitmapContextGetData(theCurrentContext);
                if (bothPixels == NULL) break;
                
                int w = (int)(CGBitmapContextGetBytesPerRow(theCurrentContext) / 4);
                int h = floor(theSize.height);
                NSUInteger *pixelData = (NSUInteger*)malloc(sizeof(NSUInteger) * 4);
                for (int y = 0; y < h; y++) {
                    for (int x = 0; x < w; x++) {
                        int i = x + y * w;
                        
                        int bothR = bothPixels[i].r;
                        int bothG = bothPixels[i].g;
                        int bothB = bothPixels[i].b;
                        
                        [theAncestorRep getPixel:pixelData atX:x y:y];
                        int backR = (int)pixelData[0];
                        int backG = (int)pixelData[1];
                        int backB = (int)pixelData[2];
                        
                        if (bothR == backR && bothG == backG && bothB == backB) { // DROP BACKGROUND
                            bothPixels[i].a = 0;
                            bothPixels[i].r = 0;
                            bothPixels[i].g = 0;
                            bothPixels[i].b = 0;
                        } else {
                            
                            float backRf = ((float)backR) / 255.0;
                            float backGf = ((float)backG) / 255.0;
                            float backBf = ((float)backB) / 255.0;
                            
                            float bothRf = ((float)bothR) / 255.0;
                            float bothGf = ((float)bothG) / 255.0;
                            float bothBf = ((float)bothB) / 255.0;
                            
                            float alphaRf = 1 - bothRf;
                            float alphaGf = 1 - bothGf;
                            float alphaBf = 1 - bothBf;
                            
                            float alpha = MAX(MAX(alphaRf,alphaGf),alphaBf); // new alpha
                            
                            float finalRf = bothRf - (backRf * (1-alpha)); // new color
                            float finalGf = bothGf - (backGf * (1-alpha)); // new color
                            float finalBf = bothBf - (backBf * (1-alpha)); // new color
                            
                            bothPixels[i].r = (int)roundf(finalRf * 255);
                            bothPixels[i].g = (int)roundf(finalGf * 255);
                            bothPixels[i].b = (int)roundf(finalBf * 255);
                            bothPixels[i].a = (int)roundf(alpha * 255);
                        }
                    }
                }
                free(pixelData);
                break;
            }
            theOpaqueAncestor = theOpaqueAncestor.superview;
        }
        self.isDrawingInterior = NO;
    }
}

@end
