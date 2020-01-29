//
// CPResiableImageView.j
// CPResiableImageView
//
// Created by Jasper De Beuckeleer
//

@import <AppKit/CALayer.j>

// ************************************** CPView **************************************

@implementation CPResiableImageView : CPView
{
    CALayer     _rootLayer;

    CALayer     _croppedAreaLayer;
    CALayer     _borderLayerCrop;
    CALayer     _borderLayerResize;
    CALayer     _imageLayer;

    CPImage     _image @accessors;
    CGPoint     _startPoint_local;

    float       _deltaXLeft;
    float       _deltaXRight;
    float       _deltaYUp;
    float       _deltaYDown;

    float       _rotationRadians;
    float       _scale;
    float       _scaleX;
    float       _scaleY;
    float       _positionX;
    float       _positionY;

    BOOL        crop @accessors;
    BOOL        resize @accessors;
}

- (id)initWithImage:(CPImage)anImage
{
    self = [super initWithFrame:CGRectMake(0.0, 0.0, [anImage size].width, [anImage size].height)];

    if (self)
    {
        _deltaXRight = 0;
        _deltaXLeft = 0;
        _deltaYUp = 0;
        _deltaYDown = 0;

        _rootLayer = [CALayer layer];

        _startPoint_local = CGPointMakeZero();

        [self setWantsLayer:YES];
        [self setLayer:_rootLayer];

        [_rootLayer setBackgroundColor:[CPColor whiteColor]];

        _rotationRadians = 0.0;
        _scale = 1.0;
        _scaleX = 1.0;
        _scaleY = 1.0;
        _positionX = 0.0;
        _positionY = 0.0;

        _imageLayer = [CALayer layer];
        [_imageLayer setDelegate:self];

        [_imageLayer setBounds:CGRectMake(0.0, 0.0, [anImage size].width, [anImage size].height)];
        [_imageLayer setAnchorPoint:CGPointMakeZero()];
        [_imageLayer setPosition:CGPointMake(0, 0)];

        _image = anImage;
        if (_image)
            [_imageLayer setBounds:CGRectMake(0.0, 0.0, [_image size].width, [_image size].height)];

        [_rootLayer addSublayer:_imageLayer];
        [_imageLayer setNeedsDisplay];

        _croppedAreaLayer = [CALayer layer];
        [_croppedAreaLayer setAnchorPoint:CGPointMakeZero()];
        [_croppedAreaLayer setBounds:[self bounds]];
        [_croppedAreaLayer setDelegate:self];
        [_rootLayer addSublayer:_croppedAreaLayer];

        _borderLayerCrop = [CALayer layer];
        [_borderLayerCrop setAnchorPoint:CGPointMakeZero()];
        [_borderLayerCrop setBounds:[self bounds]];
        [_borderLayerCrop setDelegate:self];
        [_rootLayer addSublayer:_borderLayerCrop];

        _borderLayerResize = [CALayer layer];
        [_borderLayerResize setAnchorPoint:CGPointMakeZero()];
        [_borderLayerResize setBounds:[self bounds]];
        [_borderLayerResize setDelegate:self];
        [_rootLayer addSublayer:_borderLayerResize];

        [_rootLayer setNeedsDisplay];
    }

    return self;
}

- (void)setTranslucentCroppingBorder:(BOOL)isCropping
{
    if(isCropping)
        [_croppedAreaLayer setOpacity:0.5]; // semi transparant
    else
        [_croppedAreaLayer setOpacity:1.0]; // opaque
}

- (void)drawLayer:(CALayer)aLayer inContext:(CGContext)aContext
{
    CGContextSetFillColor(aContext, [CPColor whiteColor]);

    var bounds = [aLayer bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    if(aLayer == _borderLayerCrop && crop)
    {
        // Blue border arround image
        CGContextSetFillColor(aContext, [CPColor blueColor]);
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               _deltaYUp,               width - _deltaXRight - _deltaXLeft,     1));
        CGContextFillRect(aContext, CGRectMake(width - _deltaXRight,      _deltaYUp,               -1,                                      height - _deltaYUp - _deltaYDown));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               height- _deltaYDown,     width - _deltaXRight - _deltaXLeft,     -1));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               _deltaYUp,               1,                                      height - _deltaYUp - _deltaYDown));

        // Corners for cropping image
        CGContextSetFillColor(aContext, [CPColor blackColor]);
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,             _deltaYUp,             20,      5));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,             _deltaYUp,             5,      20));

        CGContextFillRect(aContext, CGRectMake(width- _deltaXRight,     _deltaYUp,             -20,      5));
        CGContextFillRect(aContext, CGRectMake(width- _deltaXRight,     _deltaYUp,             -5,      20));

        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,             height-_deltaYDown,    20,      -5));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,             height-_deltaYDown,    5,      -20));

        CGContextFillRect(aContext, CGRectMake(width-_deltaXRight,      height-_deltaYDown,    -20,      -5));
        CGContextFillRect(aContext, CGRectMake(width-_deltaXRight,      height-_deltaYDown,    -5,      -20));
    }

    if(aLayer == _croppedAreaLayer)
    {
        CGContextFillRect(aContext, CGRectMake(0.0,                     0.0,                   width,          _deltaYUp));
        CGContextFillRect(aContext, CGRectMake(0.0,                     _deltaYUp,             _deltaXLeft,   height - _deltaYUp - _deltaYDown));
        CGContextFillRect(aContext, CGRectMake(width - _deltaXRight,    _deltaYUp,              _deltaXRight,    height - _deltaYUp - _deltaYDown));
        CGContextFillRect(aContext, CGRectMake(0.0,                     height - _deltaYDown,  width,          _deltaYDown));
    }

    if(aLayer == _borderLayerResize && resize)
    {
        // Blue border arround image
        CGContextSetFillColor(aContext, [CPColor blueColor]);
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               _deltaYUp,               width - _deltaXRight - _deltaXLeft,     1));
        CGContextFillRect(aContext, CGRectMake(width - _deltaXRight,      _deltaYUp,               -1,                                      height - _deltaYUp - _deltaYDown));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               height- _deltaYDown,     width - _deltaXRight - _deltaXLeft,     -1));
        CGContextFillRect(aContext, CGRectMake(_deltaXLeft,               _deltaYUp,               1,                                      height - _deltaYUp - _deltaYDown));

        // Corners for resizing image
        CGContextSetFillColor(aContext, [CPColor blackColor]);
        //CGContextFillRect(aContext, CGRectMake(_deltaXLeft,              _deltaYUp,             7,      7));
        //CGContextFillRect(aContext, CGRectMake(width- _deltaXRight -7,     _deltaYUp,             7,      7));
        //CGContextFillRect(aContext, CGRectMake(_deltaXLeft,              height-_deltaYDown-7,    7,      7));
        CGContextFillRect(aContext, CGRectMake(width-_deltaXRight-7,       height-_deltaYDown-7,    7,      7));

        CGContextSetFillColor(aContext, [CPColor whiteColor]);
        //CGContextFillRect(aContext, CGRectMake(_deltaXLeft+1,             _deltaYUp+1,              5,      5));
        //CGContextFillRect(aContext, CGRectMake(width- _deltaXRight-6,     _deltaYUp+1,              5,      5));
        //CGContextFillRect(aContext, CGRectMake(_deltaXLeft+1,             height-_deltaYDown-6,     5,      5));
        CGContextFillRect(aContext, CGRectMake(width-_deltaXRight-6,      height-_deltaYDown-6,     5,      5));
    }

    if(aLayer == _imageLayer )
    {
        var bounds = [aLayer bounds];

        if ([_image loadStatus] != CPImageLoadStatusCompleted)
            [_image setDelegate:self];
        else
            CGContextDrawImage(aContext, bounds, _image);
    }
}

- (void)mouseDown:(CPEvent)anEvent
{
    _startPoint_local = [self convertPointFromBase:[anEvent locationInWindow]];

    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);


    // If mouse is double clicked
    if ([anEvent clickCount] == 2 && !resize)
    {
        // If double clicked and cropping is active, disable cropping
        if(crop)
        {
            crop = NO;
            resize = NO;

            [self setTranslucentCroppingBorder:NO];

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
            [_borderLayerResize setNeedsDisplay];
        }
        // If double clicked and cropping is not active, enable cropping
        else
        {
            crop = YES;
            resize = NO;

            [self setTranslucentCroppingBorder:YES];

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
            [_borderLayerResize setNeedsDisplay];
        }   
    }

    // If single clicked the cursor is the image is not cropped and not outside the 
    if ([anEvent clickCount] == 1 && !crop
        // Not resizing while moving left point up
        && !(_startPoint_local.x > _deltaXLeft && _startPoint_local.x < _deltaXLeft +10
            && _startPoint_local.y > _deltaYUp && _startPoint_local.y < _deltaYUp + 10)
        // Not resizing while moving right point up
        && !((_startPoint_local.x > (width - _deltaXRight - 10) && _startPoint_local.x < (width - _deltaXRight)
            && _startPoint_local.y > _deltaYUp && _startPoint_local.y < _deltaYUp + 10))
        // Not resizing while moving left point down
        && !(_startPoint_local.x > _deltaXLeft && _startPoint_local.x < _deltaXLeft +10
            && _startPoint_local.y > (height - _deltaYDown - 10) && _startPoint_local.y < (height - _deltaYDown ))
        // Not resizing while moving right point down
        && !(_startPoint_local.x > (width - _deltaXRight - 10) && _startPoint_local.x < (width - _deltaXRight)
            && _startPoint_local.y > (height - _deltaYDown - 10) && _startPoint_local.y < (height - _deltaYDown )))
    {
        // If single clicked and resizing is active, disable resizing
        if(resize)
        {
            crop = NO;
            resize = NO;
            
            [self setTranslucentCroppingBorder:NO];

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
            [_borderLayerResize setNeedsDisplay];
        }
        // If single clicked and resizing is not active, enable resizing
        else
        {
            crop = NO;
            resize = YES;

            [self setTranslucentCroppingBorder:NO];

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
            [_borderLayerResize setNeedsDisplay];
        }
    }
}

-(void)mouseDragged:(CPEvent)anEvent
{
    var bounds = [self bounds],
        width = CGRectGetWidth(bounds),
        height = CGRectGetHeight(bounds);

    if(resize)
    {
        // Resizing - Moving upper left point
        if(_startPoint_local.x > _deltaXLeft && _startPoint_local.x < _deltaXLeft +10
            && _startPoint_local.y > _deltaYUp && _startPoint_local.y < _deltaYUp + 10)
        {
            // Not implemented as Pages does not gives this resizing option when an image is in between of the text
        }
        // Resizing - Moving right upper point
        else if(_startPoint_local.x > (width - _deltaXRight - 10) && _startPoint_local.x < (width - _deltaXRight)
            && _startPoint_local.y > _deltaYUp && _startPoint_local.y < _deltaYUp + 10)
        {
            // Not implemented as Pages does not gives this resizing option when an image is in between of the text
        }
        // Resizing - Moving left bottom point
        else if(_startPoint_local.x > _deltaXLeft && _startPoint_local.x < _deltaXLeft +10
            && _startPoint_local.y > (height - _deltaYDown - 10) && _startPoint_local.y < (height - _deltaYDown ))
        {
            // Not implemented as Pages does not gives this resizing option when an image is in between of the text
        }
        // Resizing - Moving right bottom point
        else if(_startPoint_local.x > (width - _deltaXRight - 10) && _startPoint_local.x < (width - _deltaXRight)
            && _startPoint_local.y > (height - _deltaYDown - 10) && _startPoint_local.y < (height - _deltaYDown ))
        {
            _startPoint_local.x = _startPoint_local.x + [anEvent deltaX];
            _startPoint_local.y = _startPoint_local.y + [anEvent deltaY];

            [_rootLayer setBounds:CGRectMake(0.0, 0.0, [self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];

            [_imageLayer setBounds:CGRectMake(0.0, 0.0, [self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];
            [self setScaleX:([self frameSize].width+[anEvent deltaX])/[self frameSize].width scaleY:([self frameSize].height+[anEvent deltaY])/[self frameSize].height];

            [_croppedAreaLayer setBounds:CGRectMake(0.0, 0.0, [self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];
            [_borderLayerCrop setBounds:CGRectMake(0.0, 0.0, [self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];
            [_borderLayerResize setBounds:CGRectMake(0.0, 0.0, [self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];
            
            [self setFrameSize:CGSizeMake([self frameSize].width+[anEvent deltaX], [self frameSize].height+[anEvent deltaY])];

            [_rootLayer setNeedsDisplay];
            [_imageLayer setNeedsDisplay];
            [_croppedAreaLayer setNeedsDisplay];

            [_borderLayerResize setNeedsDisplay];
        }
    }

    if(crop)
    {
        // Cropping - Moving upper left point
        if(_startPoint_local.x > _deltaXLeft - 5 && _startPoint_local.x < _deltaXLeft + 20
            && _startPoint_local.y > _deltaYUp - 5 && _startPoint_local.y < _deltaYUp + 20)
        {
            if(_deltaXLeft + [anEvent deltaX] > 2)
            {
                _deltaXLeft = _deltaXLeft + [anEvent deltaX];
                _startPoint_local.x = _startPoint_local.x + [anEvent deltaX];
            }

            if(_deltaYUp + [anEvent deltaY] > 2)
            {
                _deltaYUp = _deltaYUp + [anEvent deltaY];
                _startPoint_local.y = _startPoint_local.y + [anEvent deltaY];
            }   

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
        }
        // Cropping - Moving upper right point
        else if(_startPoint_local.x > (width - _deltaXRight - 20) && _startPoint_local.x < (width - _deltaXRight + 5)
            && _startPoint_local.y > _deltaYUp - 5 && _startPoint_local.y < _deltaYUp + 20)
        {
            if(_deltaXRight - [anEvent deltaX] > 2)
            {
                _deltaXRight = _deltaXRight - [anEvent deltaX];
                _startPoint_local.x = _startPoint_local.x + [anEvent deltaX];
            }

            if(_deltaYUp + [anEvent deltaY] > 2)
            {
                _deltaYUp = _deltaYUp + [anEvent deltaY];
                _startPoint_local.y = _startPoint_local.y + [anEvent deltaY];
            }

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
        }
        // Cropping - Moving bottom left point
        else if(_startPoint_local.x > _deltaXLeft - 5 && _startPoint_local.x < _deltaXLeft + 20
            && _startPoint_local.y > (height - _deltaYDown - 20) && _startPoint_local.y < (height - _deltaYDown + 5))
        {
            if(_deltaXLeft + [anEvent deltaX] > 2)
            {
                _deltaXLeft = _deltaXLeft + [anEvent deltaX];
                _startPoint_local.x = _startPoint_local.x + [anEvent deltaX];
            }

            if(_deltaYDown - [anEvent deltaY] > 2)
            {
                _deltaYDown = _deltaYDown - [anEvent deltaY];
                _startPoint_local.y = _startPoint_local.y + [anEvent deltaY];
            }

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
        }
        // Cropping - Moving bottom right point
        else if(_startPoint_local.x > (width - _deltaXRight - 20) && _startPoint_local.x < (width - _deltaXRight + 5)
            && _startPoint_local.y > (height - _deltaYDown - 20) && _startPoint_local.y < (height - _deltaYDown + 5))
        {
            if(_deltaXRight - [anEvent deltaX] > 2)
            {
                _deltaXRight = _deltaXRight - [anEvent deltaX];
                _startPoint_local.x = _startPoint_local.x + [anEvent deltaX];
            }

            if(_deltaYDown - [anEvent deltaY] > 2)
            {
                _deltaYDown = _deltaYDown - [anEvent deltaY];
                _startPoint_local.y = _startPoint_local.y + [anEvent deltaY];
            }

            [_croppedAreaLayer setNeedsDisplay];
            [_borderLayerCrop setNeedsDisplay];
        }
        // Cropping - Translate image
        else
        {
            [self setTranslateX:[anEvent deltaX] translateY:[anEvent deltaY]];
        }
    }
}

/* --------------------- */

- (void)setBounds:(CGRect)aRect
{
    [super setBounds:aRect];

    [_imageLayer setPosition:CGPointMake(CGRectGetMidX(aRect), CGRectGetMidY(aRect))];
}

- (void)setRotationRadians:(float)radians
{
    if (_rotationRadians == radians)
        return;

    _rotationRadians = radians;

    [_imageLayer setAffineTransform:CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(_rotationRadians), _scale, _scale),_positionX,_positionY)];
}

- (void)setScaleX:(float)aScaleX scaleY:(float)aScaleY
{
    _scaleX = aScaleX;
    _scaleY = aScaleY;

    [_imageLayer setAffineTransform:CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(_rotationRadians), _scaleX, _scaleY),_positionX,_positionY)];
}

- (void)setTranslateX:(float)deltaX translateY:(float)deltaY
{
    if (0 == deltaX && 0 == deltaY)
        return;

    _positionX = _positionX + deltaX;
    _positionY = _positionY + deltaY;

    [_imageLayer setAffineTransform:CGAffineTransformTranslate(CGAffineTransformScale(CGAffineTransformMakeRotation(_rotationRadians), _scaleX, _scaleY),_positionX,_positionY)];
}

- (void)drawInContext:(CGContext)aContext
{
    CGContextSetFillColor(aContext, [CPColor whiteColor]);
    CGContextFillRect(aContext, [self bounds]);
}

- (void)imageDidLoad:(CPImage)anImage
{
    [_imageLayer setNeedsDisplay];
}

@end

@implementation CPResiableImageView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        _deltaXLeft = [aCoder decodeFloatForKey:"_deltaXLeft"];
        _deltaXRight = [aCoder decodeFloatForKey:"_deltaXRight"];
        _deltaYUp = [aCoder decodeFloatForKey:"_deltaYUp"];
        _deltaYDown = [aCoder decodeFloatForKey:"_deltaYDown"];

        _rotationRadians = [aCoder decodeFloatForKey:"_rotationRadians"];
        _scale = [aCoder decodeFloatForKey:"_scale"];
        _scaleX = [aCoder decodeFloatForKey:"_scaleX"];
        _scaleY = [aCoder decodeFloatForKey:"_scaleY"];
        _positionX = [aCoder decodeFloatForKey:"_positionX"];
        _positionY = [aCoder decodeFloatForKey:"_positionY"];

        _startPoint_local = [aCoder decodePointForKey:"_startPoint_local"];

        crop = [aCoder decodeBoolForKey:"crop"];
        resize = [aCoder decodeBoolForKey:"resize"];

        _image = [aCoder decodeObjectForKey:"_image"];

        // Init
        [self setWantsLayer:YES];
        [self setLayer:_rootLayer];

        [_rootLayer setBackgroundColor:[CPColor whiteColor]]; 

        _imageLayer = [CALayer layer];
        [_imageLayer setDelegate:self];

        [_imageLayer setBounds:CGRectMake(0.0, 0.0, [_image size].width, [_image size].height)];
        [_imageLayer setAnchorPoint:CGPointMakeZero()];
        [_imageLayer setPosition:CGPointMake(0, 0)];

        if (_image)
            [_imageLayer setBounds:CGRectMake(0.0, 0.0, [_image size].width, [_image size].height)];

        [_rootLayer addSublayer:_imageLayer];
        [_imageLayer setNeedsDisplay];

        _croppedAreaLayer = [CALayer layer];
        [_croppedAreaLayer setAnchorPoint:CGPointMakeZero()];
        [_croppedAreaLayer setBounds:[self bounds]];
        [_croppedAreaLayer setDelegate:self];
        [_rootLayer addSublayer:_croppedAreaLayer];

        _borderLayerCrop = [CALayer layer];
        [_borderLayerCrop setAnchorPoint:CGPointMakeZero()];
        [_borderLayerCrop setBounds:[self bounds]];
        [_borderLayerCrop setDelegate:self];
        [_rootLayer addSublayer:_borderLayerCrop];

        _borderLayerResize = [CALayer layer];
        [_borderLayerResize setAnchorPoint:CGPointMakeZero()];
        [_borderLayerResize setBounds:[self bounds]];
        [_borderLayerResize setDelegate:self];
        [_rootLayer addSublayer:_borderLayerResize];

        [_rootLayer setNeedsDisplay];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeFloat:_deltaXLeft forKey:"_deltaXLeft"];
    [aCoder encodeFloat:_deltaXRight forKey:"_deltaXRight"];
    [aCoder encodeFloat:_deltaYUp forKey:"_deltaYUp"];
    [aCoder encodeFloat:_deltaYDown forKey:"_deltaYDown"];

    [aCoder encodeFloat:_rotationRadians forKey:"_rotationRadians"];
    [aCoder encodeFloat:_scale forKey:"_scale"];
    [aCoder encodeFloat:_scaleX forKey:"_scaleX"];
    [aCoder encodeFloat:_scaleY forKey:"_scaleY"];
    [aCoder encodeFloat:_positionX forKey:"_positionX"];
    [aCoder encodeFloat:_positionY forKey:"_positionY"];

    [aCoder encodeBool:crop forKey:"crop"];
    [aCoder encodeBool:resize forKey:"resize"];

    [aCoder encodePoint:_startPoint_local forKey:"_startPoint_local"];

    [aCoder encodeObject:_image forKey:"_image"];
}

@end
