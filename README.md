SubPixelWithoutBackground
=========================

Experimental drawing of sub-pixel antialiased text in a CALayer with a transparent background.

A layer backed NSTextField label has a layer with an NSTextLayer sublayer with an _NSLinearMaskBackingLayer sublayer. The layers are not opaque, and the antialiased portions of text are partially transparent.

This achieves something close by drawing the background, which is removed by manipulating raw pixel data. It's still not quite right, I suspect color space problems. There also appears to be a threshold below which there is no drawing, that I have not replicated.

Clicking in the window moves a thin white CALayer behind the text fields, letting you see the effect.

This class is not intended to be used directly, the technique is only of interest if you're animating text.
