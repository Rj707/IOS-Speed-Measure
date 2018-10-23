//
//  TestSpeedViewController.m
//  SpeedTest
//
//  Created by Hafiz Saad on 23/10/2018.
//  Copyright © 2018 Hafiz Saad. All rights reserved.
//

#import "TestSpeedViewController.h"

@interface TestSpeedViewController () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic) CFAbsoluteTime startTime;
@property (nonatomic) CFAbsoluteTime stopTime;
@property (nonatomic) long long bytesReceived;
@property (nonatomic, copy) void (^speedTestCompletionHandler)(CGFloat megabytesPerSecond, NSError *error);
@property (nonatomic, strong) NSMutableArray * measurementsArray;

@end

@implementation TestSpeedViewController



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.measurementsArray = [[NSMutableArray alloc] init];
    [self measureConnectionSpeed];
}

- (void) measureConnectionSpeed
{
    [self.refreshButton setUserInteractionEnabled:false];
    self.refreshButton.alpha = 0.4;
    self.label7.text = @"Calculating Average...";
    for (int i=0; i<5; i++)
    {
        [self testDownloadSpeedWithTimout:5.0 completionHandler:^(CGFloat megabytesPerSecond, NSError *error)
         {
             NSLog(@"megabytesPerSecond %0.5f; error = %@", megabytesPerSecond*8000, error);
             dispatch_async(dispatch_get_main_queue(), ^
            {
                self.label1.text = [NSString stringWithFormat:@"Total Bytes Received: %lld", self->_bytesReceived];
                self.label2.text = [NSString stringWithFormat:@"Start Time: %f", self->_startTime];
                self.label3.text = [NSString stringWithFormat:@"End Time: %f", self->_stopTime];
                self.label4.text = [NSString stringWithFormat:@"Megabytes Per Second: %f", megabytesPerSecond];
                self.label5.text = [NSString stringWithFormat:@"Kilobit Per Second: %f", megabytesPerSecond*8000];
                self.label6.text = [NSString stringWithFormat:@"TimeTaken: %.2f Secs", self->_stopTime - self->_startTime];
                [self.measurementsArray addObject:[NSString stringWithFormat:@"%.0f", megabytesPerSecond*8000]];
                if (self.measurementsArray.count == 5)
                {
                    [self calculateTheAverage];
                    [self.refreshButton setUserInteractionEnabled:true];
                    self.refreshButton.alpha = 1.0;
                }
                else
                {
                    
                }
            });
         }];
    }
    
}

- (void) calculateTheAverage
{
    NSNumber *average = [self.measurementsArray valueForKeyPath:@"@avg.self"];
    self.label7.text = [NSString stringWithFormat:@"Average Speed: %@ Kbps",average];
    if (average.intValue>=64)
    {
        self.label7.textColor= [UIColor greenColor];
    }
    else
    {
        self.label7.textColor= [UIColor redColor];
    }
    self.measurementsArray = [[NSMutableArray alloc] init];
}

/// Test speed of download
///
/// Test the speed of a connection by downloading some predetermined resource. Alternatively, you could add the
/// URL of what to use for testing the connection as a parameter to this method.
///
/// @param timeout             The maximum amount of time for the request.
/// @param completionHandler   The block to be called when the request finishes (or times out).
///                            The error parameter to this closure indicates whether there was an error downloading
///                            the resource (other than timeout).
///
/// @note                      Note, the timeout parameter doesn't have to be enough to download the entire
///                            resource, but rather just sufficiently long enough to measure the speed of the download.

- (void)testDownloadSpeedWithTimout:(NSTimeInterval)timeout completionHandler:(nonnull void (^)(CGFloat megabytesPerSecond, NSError * _Nullable error))completionHandler
{
    NSURL *url = [NSURL URLWithString:@"http://unec.edu.az/application/uploads/2014/12/pdf-sample.pdf"];
    
    self.startTime = CFAbsoluteTimeGetCurrent();
    self.stopTime = self.startTime;
    self.bytesReceived = 0;
    self.speedTestCompletionHandler = completionHandler;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForResource = timeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    [[session dataTaskWithURL:url] resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    self.bytesReceived += [data length];
    self.stopTime = CFAbsoluteTimeGetCurrent();
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    CFAbsoluteTime elapsed = self.stopTime - self.startTime;
    CGFloat speed = elapsed != 0 ? self.bytesReceived / (CFAbsoluteTimeGetCurrent() - self.startTime) / 1024.0 / 1024.0 : -1;
    
    // treat timeout as no error (as we're testing speed, not worried about whether we got entire resource or not
    
    if (error == nil || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorTimedOut))
    {
        self.speedTestCompletionHandler(speed, nil);
    }
    else
    {
        self.speedTestCompletionHandler(speed, error);
    }
}

- (IBAction)refresh:(id)sender
{
    [self measureConnectionSpeed];
}

@end
