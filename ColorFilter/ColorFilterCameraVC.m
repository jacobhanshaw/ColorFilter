//
//  ColorFilterCameraVC.m
//  Test
//
//  Created by Jacob Hanshaw on 3/3/14.
//  Copyright (c) 2014 Jacob Hanshaw. All rights reserved.
//

#import "ColorFilterCameraVC.h"

#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

#import "NMRangeSlider.h"

@interface ColorFilterCameraVC () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) CALayer *customPreviewLayer;

@end

typedef enum {
    CameraDeviceSetting640x480 = 0,
    CameraDeviceSettingHigh = 1,
    CameraDeviceSettingMedium = 2,
    CameraDeviceSettingLow = 3,
} CameraDeviceSetting;

@implementation ColorFilterCameraVC
{
    AVCaptureSession *_captureSession;
    AVCaptureVideoDataOutput *_dataOutput;
    CameraDeviceSetting cameraDeviceSetting;
    
    CALayer *_customPreviewLayer;
    
    UILabel *redName;
    NMRangeSlider *redSlider;
    UILabel *redLeft;
    UILabel *redRight;
        UILabel *blueName;
    NMRangeSlider *blueSlider;
    UILabel *blueLeft;
    UILabel *blueRight;
        UILabel *greenName;
    NMRangeSlider *greenSlider;
    UILabel *greenLeft;
    UILabel *greenRight;
}

@synthesize captureSession = _captureSession;
@synthesize dataOutput = _dataOutput;
@synthesize customPreviewLayer = _customPreviewLayer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCameraSession];
    [self setUpSliders];
    
        if (![_captureSession isRunning])
    [_captureSession startRunning];
}

- (void) viewDidAppear:(BOOL)animated
{
    [self sliderValueChanged:redSlider];
    [self sliderValueChanged:greenSlider];
    [self sliderValueChanged:blueSlider];
}

- (void)setupCameraSession
{
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession beginConfiguration];
#pragma mark performance edit
    
    
    [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    
    AVCaptureDevice *device = [AVCaptureDevice
                               defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ( [device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480])
    {
        cameraDeviceSetting = CameraDeviceSetting640x480;
        [_captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    else
    {
        if ( [device supportsAVCaptureSessionPreset:AVCaptureSessionPresetHigh] )
        {
            cameraDeviceSetting = CameraDeviceSettingHigh;
            [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        }
        else if ( [device supportsAVCaptureSessionPreset:AVCaptureSessionPresetMedium] )
        {
            cameraDeviceSetting = CameraDeviceSettingMedium;
            [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
        }
        else if ( [device supportsAVCaptureSessionPreset:AVCaptureSessionPresetLow] )
        {
            cameraDeviceSetting = CameraDeviceSettingLow;
            [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
        }
    }
    
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput
                                   deviceInputWithDevice:device error:&error];
    if(error != nil)
        NSLog(@"Error: %@", error);
    
    if ([_captureSession canAddInput:input])
        [_captureSession addInput:input];
    
    _customPreviewLayer = [CALayer layer];
    _customPreviewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    _customPreviewLayer.position = CGPointMake(self.view.frame.size.width/2., self.view.frame.size.height/2.);
    _customPreviewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);
    [self.view.layer addSublayer:_customPreviewLayer];
    
    _dataOutput = [[AVCaptureVideoDataOutput
                                         alloc] init];
    [_dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:
                              [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                         forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ( [_captureSession canAddOutput:_dataOutput])
        [_captureSession addOutput:_dataOutput];
    
    [_captureSession commitConfiguration];
    
    dispatch_queue_t queue = dispatch_queue_create ("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [_dataOutput setSampleBufferDelegate:self queue:queue];
}

- (void) setUpSliders
{
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;

    redName = [[UILabel alloc] initWithFrame:CGRectMake(5, height - 80, 20, 20)];
    redName.text = @"R: ";
    float originX = redName.frame.origin.x+redName.frame.size.width;
    redSlider= [[NMRangeSlider alloc] initWithFrame:CGRectMake(originX, height- 80, width - originX *2, 20)];
    redSlider.minimumValue = 0;
    redSlider.maximumValue = 255;
    [redSlider setLowerValue:(arc4random() % 100) upperValue:155+(arc4random() % 100) animated:NO];
    [redSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    redLeft = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    redLeft.textAlignment = NSTextAlignmentCenter;
    redRight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    redRight.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:redName];
    [self.view addSubview:redSlider];
    [self.view addSubview:redLeft];
    [self.view addSubview:redRight];
    
    greenName = [[UILabel alloc] initWithFrame:CGRectMake(5, height - 50, 20, 20)];
    greenName.text = @"G: ";
    greenSlider= [[NMRangeSlider alloc] initWithFrame:CGRectMake(originX, height - 50, width - 2 * originX, 20)];
    greenSlider.minimumValue = 0;
    greenSlider.maximumValue = 255;
    [greenSlider setLowerValue:(arc4random() % 100) upperValue:155+(arc4random() % 100) animated:NO];
    [greenSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    greenLeft = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    greenLeft.textAlignment = NSTextAlignmentCenter;
    greenRight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    greenRight.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:greenName];
    [self.view addSubview:greenSlider];
    [self.view addSubview:greenLeft];
    [self.view addSubview:greenRight];
    
    blueName = [[UILabel alloc] initWithFrame:CGRectMake(5, height - 20, 20, 20)];
    blueName.text = @"B: ";
    blueSlider= [[NMRangeSlider alloc] initWithFrame:CGRectMake(originX, height - 20, width - 2 * originX, 20)];
    blueSlider.minimumValue = 0;
    blueSlider.maximumValue = 255;
    [blueSlider setLowerValue:(arc4random() % 100) upperValue:155+(arc4random() % 100) animated:NO];
    [blueSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    blueLeft = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    blueLeft.textAlignment = NSTextAlignmentCenter;
    blueRight = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    blueRight.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:blueName];
    [self.view addSubview:blueSlider];
    [self.view addSubview:blueLeft];
    [self.view addSubview:blueRight];

}

- (IBAction)sliderValueChanged:(NMRangeSlider*)sender
{
    UILabel *lowerLabel = redLeft;
    UILabel *upperLabel = redRight;
    
    if(sender == blueSlider)
    {
        lowerLabel = blueLeft;
        upperLabel = blueRight;
    }
    else if(sender == greenSlider)
    {
        lowerLabel = greenLeft;
        upperLabel = greenRight;
    }
    
    CGPoint lowerCenter;
    lowerCenter.x = (sender.lowerCenter.x + sender.frame.origin.x);
    lowerCenter.y = (sender.center.y - 30.0f);
    lowerLabel.center = lowerCenter;
    lowerLabel.text = [NSString stringWithFormat:@"%d", (int)sender.lowerValue];
    
    CGPoint upperCenter;
    upperCenter.x = (sender.upperCenter.x + sender.frame.origin.x);
    upperCenter.y = (sender.center.y - 30.0f);
    upperLabel.center = upperCenter;
    upperLabel.text = [NSString stringWithFormat:@"%d", (int)sender.upperValue];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    int bufferSize = bytesPerRow * height;
    int pixelBytes = bytesPerRow/width;
    
    uint8_t *tempAddress = malloc( bufferSize );
    memcpy( tempAddress, baseAddress, bytesPerRow * height );
    
    baseAddress = tempAddress;
    
    int lowBlue = blueSlider.lowerValue;
    int highBlue = blueSlider.upperValue;
    int lowGreen = greenSlider.lowerValue;
    int highGreen = greenSlider.upperValue;
    int lowRed = redSlider.lowerValue;
    int highRed = redSlider.upperValue;
    
    for( int row = 0; row < height; row++ ) {
        for( int column = 0; column < width; column++ ) {
            
            unsigned char *pixel = baseAddress + (row * bytesPerRow) +
            (column * pixelBytes);
            
            if(   pixel[0] >= lowBlue  && pixel[0] <= highBlue
               && pixel[1] >= lowGreen && pixel[1] <= highGreen
               && pixel[2] >= lowRed   && pixel[2] <= highRed)
            {
                pixel[0] = 255;
                pixel[1] = 255;
                pixel[2] = 255;
            }
            
        }
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = nil;
    
    if (cameraDeviceSetting != CameraDeviceSetting640x480)        // not an iPhone4 or iTouch 5th gen
        newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,  kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    else
        newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        _customPreviewLayer.contents = (__bridge id)newImage;
    });
    
    CGImageRelease(newImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(newContext);
    
    free(tempAddress);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer,0);
}

@end