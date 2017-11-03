//
//  SegmentedViewController.m
//  
//
//  Created by zcheng on 2015-03-18.
//
//

#import "SegmentedViewController.h"
#import "FilterTableViewController.h"
#import <stdlib.h>
#import "Go_Arch-Swift.h"



#define SORTNAME @"sortName"
#define SORTPRICEHIGH @"sortPriceHigh"
#define SORTPRICELOW @"sortPriceLow"

@interface SegmentedViewController ()

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index;

@end

@implementation SegmentedViewController {
    BOOL deleteRaw;
}

- (void)viewDidLoad {
    [super viewDidLoad];
                                                                
    // Do any additional setup after loading the view.
    // init vars
    appDelegate = [[UIApplication sharedApplication] delegate];
    account = appDelegate.account;
    self.dataWrapper = appDelegate.dataWrapper;
    self.localDevice = [self.dataWrapper getDevice:account.cid];
    defaults = [NSUserDefaults standardUserDefaults];
    self.albums = [self.dataWrapper getAllAlbums];
    
    self.saveFunction = [[SaveToDocument alloc]init];
    
    [self getViewController];
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    if (filterFlag != 1) {
        self.albums = [self.dataWrapper getAllAlbums];
    }
    if (sortFlag != nil) {
        [self sortarrays:sortFlag];
    } else {
    [self getViewController];
    }
}

- (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordChanged" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addNewPhoto" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkStatusChanged" object:nil];
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
    [self addChildViewController:vc];
    [self transitionFromViewController:self.currentViewController toViewController:vc duration:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.currentViewController.view removeFromSuperview];
        vc.view.frame = self.containerView.bounds;

        [self.view addSubview:vc.view];
    } completion:^(BOOL finished) {
        [vc didMoveToParentViewController:self];
        [self.currentViewController removeFromParentViewController];
        self.currentViewController = vc;
    }];
    self.navigationItem.title = vc.title;
}

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index {
    UIViewController *vc;
    MainLocationViewController *mainvc;
    SearchMapViewController *mapvc;
    //LargePhotoViewContoller *largevc;
    ARViewController *arvc;
    self.albums = [self.dataWrapper getAllAlbums];
    
    if (sortFlag !=nil) {
        self.albums = [NSMutableArray arrayWithArray:self.sortArray];
    }
    if (filterFlag == 1) {
        self.albums = [NSMutableArray arrayWithArray:self.filterArray];
    }

    switch (index) {
        case 0:
            mainvc = (MainLocationViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"mainLocationViewController"];
            mainvc.albums = self.albums;
            vc = mainvc;
            break;
        case 1:
            mapvc = (SearchMapViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
            mapvc.albums = self.albums;
            vc = mapvc;
            break;
        case 2:
            arvc = (ARViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ARViewContoller"];
            vc = arvc;
            break;
    }
    return vc;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)resetFilter:(id)sender {
    filterFlag = 0;
    sortFlag =nil;
    self.albums = [self.dataWrapper getAllAlbums];
    [self getViewController];
}

-(void) filterInfo:(NSMutableArray *)data {
    filterFlag = 1;
    self.filterArray = data;
    [self getViewController];
    

}

#pragma mark - sort functions

-(void) sortarrays:(NSString *) sortBase {
    //NSArray *sortedArray;
    
    if ([sortBase isEqualToString:SORTNAME]) {
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *first = [(CSAlbum *)obj1 name];
            NSString *second = [(CSAlbum *)obj2 name];
            return [first compare:second];
        }];

    } else if ([sortBase isEqualToString:SORTPRICEHIGH]){
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSEntry *first = [(CSAlbum *)obj1 entry];
            CSEntry *second = [(CSAlbum *)obj2 entry];
            return [second.price compare:first.price];
        }];
        
    } else if ([sortBase isEqualToString:SORTPRICELOW]){
        self.sortArray = [self.albums sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            CSEntry *first = [(CSAlbum *)obj1 entry];
            CSEntry *second = [(CSAlbum *)obj2 entry];
            return [first.price compare:second.price];
        }];
    }
    
    self.albums = [NSMutableArray arrayWithArray:self.sortArray];
    [self getViewController];

    
}

- (IBAction)sortLocations:(id)sender {
    UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Sort" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Sort By Name",@"Sort By Price(High to Low)",@"Sort By Price(Low to High)", nil];
    [shareActionSheet showInView:self.view];
    
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    switch (buttonIndex) {
        case 0:
        {
            sortFlag = SORTNAME;
            [self sortarrays:SORTNAME];
            break;
        }
        case 1:
        {
            sortFlag = SORTPRICEHIGH;
            [self sortarrays:SORTPRICEHIGH];
            break;
        }
        case 2:
        {
            sortFlag = SORTPRICELOW;
            [self sortarrays:SORTPRICELOW];
            break;
    
        }
        default:
            break;
    }
}


-(void) getViewController {
    UIViewController *vc = [self viewControllerForSegmentIndex:self.typeSegmentedControl.selectedSegmentIndex];
    [self addChildViewController:vc];
    vc.view.frame = self.containerView.bounds;
    [self.view addSubview:vc.view];
    self.currentViewController = vc;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"filterSegue"]) {
        
        FilterTableViewController *vc = (FilterTableViewController *)segue.destinationViewController;
        vc.delegate = self;
        vc.hidesBottomBarWhenPushed = YES;
    }

}
#pragma mark - Get current location 

-(void) getCurrentLocation {
    locationManager = [[CLLocationManager alloc]init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [self geocodeLocation:newLocation];
}

- (void)geocodeLocation:(CLLocation *)location {
    if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:location
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if ([placemarks count] > 0) {
                           [self getViewController];
                       }
                   }];
    [locationManager stopUpdatingLocation];

}

@end
