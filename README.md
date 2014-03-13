SubPixelWithoutBackground
=========================

Experimental drawing of sub-pixel antialiased text in a CALayer with a transparent background.

A layer backed NSTextField label has a layer with an NSTextLayer sublayer with an _NSLinearMaskBackingLayer sublayer. The layers are not opaque, and the antialiased portions of text are partially transparent.

This achieves something close by drawing the background, which is removed by manipulating raw pixel data. It's still not quite right, I suspect color space problems.
