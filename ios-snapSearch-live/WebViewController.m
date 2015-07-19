//
//  WebViewController.m
//  ios-snapSearch-live
//
//  Created by Carter Chang on 7/19/15.
//  Copyright (c) 2015 Carter Chang. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURL *url;
@end

@implementation WebViewController

-(id) initWithUrl:(NSString *)urlStr{
    if ((self = [super initWithNibName:@"WebViewController" bundle:nil])){
        urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.url = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.url];
    [_webView loadRequest:urlRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
