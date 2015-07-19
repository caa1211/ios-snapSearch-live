
/*
 
 
-(void) updateMask {

    CGRect r = self.cameraViewMask.bounds;
    CGRect r2 = self.recognizeTarget.frame;    CAShapeLayer* lay = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, nil, r2);
    CGPathAddRect(path, nil, r);
    lay.path = path;
    CGPathRelease(path);
    lay.fillRule = kCAFillRuleEvenOdd;

    self.cameraViewMask.layer.mask = lay;
}





-(void) maskWithImage:(UIImage*) maskImage TargetView:(UIView*) targetView{
    CALayer *_maskingLayer = [CALayer layer];
    _maskingLayer.frame = targetView.bounds;
    [_maskingLayer setContents:(id)[maskImage CGImage]];
    [targetView.layer setMask:_maskingLayer];
}



- (UIImage *)blurWithCoreImage:(UIImage *)sourceImage
{
    CIImage *inputImage = [CIImage imageWithCGImage:sourceImage.CGImage];
    
    // Apply Affine-Clamp filter to stretch the image so that it does not
    // look shrunken when gaussian blur is applied
    CGAffineTransform transform = CGAffineTransformIdentity;
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:@"inputImage"];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    
    // Apply gaussian blur filter with radius of 30
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:clampFilter.outputImage forKey: @"inputImage"];
    [gaussianBlurFilter setValue:@30 forKey:@"inputRadius"];
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:gaussianBlurFilter.outputImage fromRect:[inputImage extent]];
    
    // Set up output context.
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    
    // Invert image coordinates
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.view.frame.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, self.view.frame, cgImage);
    
    // Apply white tint
    CGContextSaveGState(outputContext);
    CGContextSetFillColorWithColor(outputContext, [UIColor colorWithWhite:1 alpha:0.2].CGColor);
    CGContextFillRect(outputContext, self.view.frame);
    CGContextRestoreGState(outputContext);
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

 
 
 
 
 -(void) setupEffectButtons {
 CGRect parentRect = self.view.bounds;
 
 self.grayBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
 self.grayBtn.center = CGPointMake(parentRect.size.width - 40, 100);
 self.grayBtn.titleLabel.font = [UIFont systemFontOfSize:16];
 [self.grayBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
 self.grayBtn.animateTap = NO;
 [self.grayBtn setTitle:NSLocalizedString(@"G", nil) forState:UIControlStateNormal];
 self.grayBtn.tag = 1;
 [self.grayBtn addTarget:self action:@selector(tapOnButton:) forControlEvents:UIControlEventTouchUpInside];
 [self.view addSubview:self.grayBtn];
 
 self.invertBtn = [[DKCircleButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
 self.invertBtn.center = CGPointMake(parentRect.size.width - 90, 100);
 self.invertBtn.titleLabel.font = [UIFont systemFontOfSize:16];
 [self.invertBtn setTitleColor:[UIColor colorWithWhite:1 alpha:1.0] forState:UIControlStateNormal];
 self.invertBtn.tag = 2;
 self.invertBtn.animateTap = NO;
 [self.invertBtn setTitle:NSLocalizedString(@"I", nil) forState:UIControlStateNormal];
 
 [self.invertBtn addTarget:self action:@selector(tapOnButton:) forControlEvents:UIControlEventTouchUpInside];
 [self.view addSubview:self.invertBtn];
 
 [self updateButtonStatus:self.grayBtn];
 [self updateButtonStatus:self.invertBtn];
 }
 
 
 
 //- (UIImage*) createInvertMask:(UIImage *)maskImage withTargetImage:(UIImage *) image {
 //    CGImageRef maskRef = maskImage.CGImage;
 //    CGBitmapInfo bitmapInfo = kCGImageAlphaNone;
 //    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
 //    CGImageRef mask = CGImageCreate(CGImageGetWidth(maskRef),
 //                                    CGImageGetHeight(maskRef),
 //                                    CGImageGetBitsPerComponent(maskRef),
 //                                    CGImageGetBitsPerPixel(maskRef),
 //                                    CGImageGetBytesPerRow(maskRef),
 //                                    CGColorSpaceCreateDeviceGray(),
 //                                    bitmapInfo,
 //                                    CGImageGetDataProvider(maskRef),
 //                                    nil, NO,
 //                                    renderingIntent);
 //    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
 //    CGImageRelease(mask);
 //    CGImageRelease(maskRef);
 //    return [UIImage imageWithCGImage:masked];
 //}
 //
 //
 //-(UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
 //    CGImageRef maskRef = maskImage.CGImage;
 //    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
 //                                        CGImageGetHeight(maskRef),
 //                                        CGImageGetBitsPerComponent(maskRef),
 //                                        CGImageGetBitsPerPixel(maskRef),
 //                                        CGImageGetBytesPerRow(maskRef),
 //                                        CGImageGetDataProvider(maskRef), NULL, false);
 //
 //    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);
 //    return [UIImage imageWithCGImage:masked];
 //}

 
 
 - (void) doRecognitionNoOperation:(UIImage*)image complete:(void(^)(NSString *recognizedText))complete{
 NSString *ocrKey = self.langArray[self.ocrLang][@"ocr"];
 G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:ocrKey];
 tesseract.maximumRecognitionTime = 10.0;
 if(self.ocrLang == OCR_LANG_MODE_ENG){
 //operation.tesseract.charWhitelist = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
 }else if(self.ocrLang == OCR_LANG_MODE_NUM){
 tesseract.charWhitelist = @"0123456789";
 }else if (self.ocrLang == OCR_LANG_MODE_CHT){
 tesseract.maximumRecognitionTime = 30.0;
 }else if (self.ocrLang == OCR_LANG_MODE_JPN){
 tesseract.maximumRecognitionTime = 30.0;
 }
 tesseract.image = image;
 [tesseract recognize];
 NSString *recognizedText = tesseract.recognizedText;
 complete(recognizedText);
 }
 

 
*/