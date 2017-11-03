//
//  SinglePhotoViewController.m
//  Go Arch
//
// acdGO data backup and recovery
// © acdGO Software, Ltd., 2013-2014, All Rights Reserved.
//

#import "SinglePhotoViewController.h"

@interface SinglePhotoViewController ()

@end

@implementation SinglePhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.container addSubview:self.tagField];
    // Do any additional setup after loading the view.
    NSLog(@"is video %@",self.selectedPhoto.isVideo);
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    self.scrollView.contentSize = CGSizeMake(320, 477);
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setMaximumZoomScale:3.5];
    self.scrollView.delegate = self;
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.imageView setClipsToBounds:YES];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (self.selectedPhoto.isVideo == nil || [self.selectedPhoto.isVideo isEqualToString:@"0"]) {
        [self.view addSubview:self.scrollView];
        [self.scrollView addSubview:self.imageView];
        [self.view insertSubview:self.container aboveSubview:self.imageView];
        NSLog(@"NOT VIDEO, LOAD FULL SCREEN IMAGE");
        [appDelegate.mediaLoader loadFullScreenImage:self.selectedPhoto
                                   completionHandler:^(UIImage *image) {
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self.imageView setImage:image];
                                       });
                                   }];
    } else {
        
        NSLog(@"%@",self.selectedPhoto.isVideo);
        [self.view insertSubview:self.container aboveSubview:self.videoController.view];
        NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];
        NSString *thumburl = [documentsPath stringByAppendingPathComponent:self.selectedPhoto.imageURL];
        NSString *newUrl =[ @"file://"stringByAppendingString:thumburl];
        
        self.videoController = [[MPMoviePlayerController alloc]init];
        
        NSURL *theURL = [[NSURL alloc] initWithString:newUrl];

        [self.videoController.view setFrame:CGRectMake (0, 0, 320, 480)];
        
        [self.videoController setContentURL:theURL];
        
        [self.view addSubview:self.videoController.view];
        [self.view insertSubview:self.container aboveSubview:self.videoController.view];
        self.videoController.shouldAutoplay = NO;
        [self.videoController prepareToPlay];
        //[self.videoController play];
        
    }
    self.tagField.text = self.selectedPhoto.tag;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.tagField resignFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {

  // set nav bar title
  [self.navBar
      setTitle:[NSString stringWithFormat:@"%d / %lu", self.selected + 1,
                                          (unsigned long)self.photos.count]];

  // add share button to top nav bar
  self.navBar.rightBarButtonItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                           target:self
                           action:@selector(shareAction)];
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

# pragma mark - TextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.tagField.frame = CGRectMake(self.tagField.frame.origin.x, self.tagField.frame.origin.y - 208.0, self.tagField.frame.size.width, self.tagField.frame.size.height);
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.tagField.frame = CGRectMake(self.tagField.frame.origin.x, (self.tagField.frame.origin.y + 208.0), self.tagField.frame.size.width, self.tagField.frame.size.height);
    [UIView commitAnimations];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (IBAction) textfieldChanged:(id)sender {
    
    UITextField *text = sender;
    self.selectedPhoto.tag = text.text;
    if (self.selectedPhoto.remoteID != nil) {
        [self.dataWrapper updatePhotoTag:self.selectedPhoto.tag photoId:self.selectedPhoto.remoteID photo:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self.coinsorter updateMeta:self.selectedPhoto entity:@"tag" value:self.selectedPhoto.tag];
        });
    } else {
        [self.dataWrapper updatePhotoTag:self.selectedPhoto.tag photoId:nil photo:self.selectedPhoto];
        NSLog(@"could not update tag at this moment because the photo is not upload yet, tag will be update when uploading the photo");
    }
}

- (void)shareAction {
  
  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
  [appDelegate.mediaLoader loadFullResImage:self.selectedPhoto completionHandler:^(UIImage *image) {
    NSArray *objectsToShare = @[ image ];
    
    UIActivityViewController *activityVC =
    [[UIActivityViewController alloc] initWithActivityItems:objectsToShare
                                      applicationActivities:nil];
    
    NSArray *excludeActivities = @[ ];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    [self presentViewController:activityVC animated:YES completion:nil];
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little
 preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
