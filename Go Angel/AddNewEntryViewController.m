//
//  AddNewEntryViewController.m
//  Go Arch
//
//  Created by zcheng on 2015-03-19.
//  Copyright (c) 2015 acdGO Software Ltd. All rights reserved.
//

#import "AddNewEntryViewController.h"
#import "AddingLocationViewController.h"

@interface AddNewEntryViewController ()

@end

@implementation AddNewEntryViewController {
    NSDictionary *metadata;
    BOOL editEnabled;
    UIBarButtonItem *applyBtnmls;
    UIBarButtonItem *applyBtnprice;
    UIBarButtonItem *applyBtnyear;
    UIBarButtonItem *applyBtnbuilding;
    UIBarButtonItem *applyBtnland;
}
@synthesize location;
static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 162;
CGFloat animatedDistance;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO];
    [self setup];
    // Do any additional setup after loading the view.
}

- (void) setup {
    [self createViewContent];
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.saveFunction = [[SaveToDocument alloc]init];
    
    [self.navigationController setToolbarHidden:NO];
    if (!self.album) {
        self.location = [[CSLocation alloc]init];
        self.entry = [[CSEntry alloc]init];
        self.coverPhoto = [[CSPhoto alloc]init];
        self.album = [[CSAlbum alloc]init];
    } else {
        //self.album = self.location.album;
        self.entry = self.album.entry;
        self.location = self.album.entry.location;
        if (self.coverPhoto) {
            [self updateCoverPhoto:self.coverPhoto];
        }
        
        [self setEditEnabled:NO];
    }
    //self.metadataView = [[UIView alloc]initWithFrame:CGRectMake(0, 490, 320, 500)];
    
    self.metadataView.backgroundColor = [UIColor lightGrayColor];
    [self.scrollView addSubview:self.metadataView];
    
    if (!_usePreviousLocation) {
        UITapGestureRecognizer *tapImageView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTaped:)];
        tapImageView.numberOfTapsRequired = 1;
        tapImageView.numberOfTouchesRequired = 1;
        [self.CoverImageView addGestureRecognizer:tapImageView];
        [self.CoverImageView setUserInteractionEnabled:YES];
    }
    self.CoverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.CoverImageView.clipsToBounds = YES;
    
    self.scrollView.contentSize = CGSizeMake(320, 1500);
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    [self addToolBarOnKeyboard];
}

- (void) setEditEnabled:(BOOL)enabled {
    editEnabled = enabled;
    BOOL hidden = !enabled;
    
    [self.addressTextField setEnabled:enabled];
    [self.cityTextField setEnabled:enabled];
    [self.stateTextField setEnabled:enabled];
    [self.countryTextField setEnabled:enabled];
    [self.postcodeTextField setEnabled:enabled];
    [self.tagTextField setEnabled:enabled];
    [self.priceTextField setEnabled:enabled];
    [self.yearBuiltTextField setEnabled:enabled];
    [self.buildingSqftTextField setEnabled:enabled];
    [self.landSqftTextField setEnabled:enabled];
    [self.mlsTextField setEnabled:enabled];
    [self.nameTextField setEnabled:enabled];
    [self.descriptionTextField setEnabled:enabled];
    
    [self.mapAddingBtn setHidden:hidden];
    [self.historySelectBtn setHidden:hidden];
    [self.typeSelectBtn setHidden:hidden];
    [self.statusSelectBtn setHidden:hidden];
    [self.bedSelectBtn setHidden:hidden];
    [self.bathSelectBtn setHidden:hidden];
    
    [self.priceTextField setText:[self getPriceText]];
}

- (void) updateCoverPhoto:(CSPhoto *)photo {
    // set image to cover photo
    self.coverPhoto = photo;
    [appDelegate.mediaLoader loadThumbnail:self.coverPhoto completionHandler:^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.CoverImageView setImage:image];
        });
    }];
}

-(void) viewDidAppear:(BOOL)animated {
    
    [self fillLocationData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Choose Cover Image
-(void) imageTaped:(UIGestureRecognizer *)gestureRecognizer {
    
    UIActionSheet *shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"Cover Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Select From Album",@"Take a Photo", nil];
    [shareActionSheet showInView:self.view];
}

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    switch (buttonIndex) {
        case 0:
        {
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.mediaTypes = @[(NSString *) kUTTypeImage, (NSString *) kUTTypeVideo];
            imagePicker.allowsEditing = NO;
            [self presentViewController:imagePicker animated:YES completion:nil];
            
            break;
        }
        case 1:
        {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePicker animated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if ([info objectForKey:UIImagePickerControllerOriginalImage]){
        self.photoImage=[info objectForKey:UIImagePickerControllerOriginalImage];
        metadata = info[UIImagePickerControllerMediaMetadata];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.CoverImageView setImage:self.photoImage];
        });
    }
    
    [picker dismissViewControllerAnimated:NO completion:nil];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark TextField Delegate

-(void)dismissKeyboard {
    [self.view endEditing:YES];
    if (self.popView.visible) {
        [self.popView hide:YES];
    }
}

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    
    //the following few lines calculate how far we’ll need to scroll
    CGRect textFieldRect = [self.view.window convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds fromView:self.view];
    
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    //make sure it’s scrolling reasonably
    if (heightFraction < 0.0) {
        heightFraction = 0.0;
    }else if (heightFraction > 1.0) {
        heightFraction = 1.0;
    }
    
    //the orientation of the phone changes how much we want to scroll.
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
    }else {
        animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    
    //get the scrollview’s current size, and add the distance we want to scroll to it
    CGSize newSize = self.tableView.contentSize;
    newSize.height += animatedDistance;
    self.tableView.contentSize = newSize;
    
    //finally, scroll that distance
    CGPoint p = self.tableView.contentOffset;
    p.y += animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.tableView setContentOffset:p animated:NO];
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{

    CGSize newSize = self.tableView.contentSize;
    newSize.height -= animatedDistance;
    self.tableView.contentSize = newSize;
    
    //finally, scroll that distance
    CGPoint p = self.tableView.contentOffset;
    p.y -= animatedDistance;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.tableView setContentOffset:p animated:NO];
    
    [UIView commitAnimations];

   //self.priceTextField.text = [self getPriceText];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldValueChanged:(id)sender {
    
    // if using previous location, don't save all edits into location objectbrew up
    //    if (_usePreviousLocation) {
    //        return;
    //    }
    
    NSNumberFormatter *format = [[NSNumberFormatter alloc]init];
    format.numberStyle = NSNumberFormatterDecimalStyle;
    if (sender == self.addressTextField) {
        self.location.sublocation = self.addressTextField.text;
        [self geocodeAddress];
    } else if (sender == self.cityTextField) {
        self.location.city = self.cityTextField.text;
    } else if (sender == self.stateTextField) {
        self.location.province = self.stateTextField.text;
    } else if (sender == self.countryTextField) {
        self.location.country = self.countryTextField.text;
    } else if (sender == self.postcodeTextField) {
        self.location.postCode = self.postcodeTextField.text;
    } else if (sender == self.tagTextField) {
        self.entry.tag = self.tagTextField.text;
    } else if (sender == self.priceTextField) {
        self.entry.price = [format numberFromString: self.priceTextField.text];
    } else if (sender == self.yearBuiltTextField) {
        self.entry.yearBuilt = self.yearBuiltTextField.text;
    } else if (sender == self.buildingSqftTextField) {
        self.entry.buildingSqft = [format numberFromString: self.buildingSqftTextField.text];
    } else if (sender == self.landSqftTextField) {
        self.entry.landSqft = [format numberFromString: self.landSqftTextField.text];
    } else if (sender == self.mlsTextField) {
        self.entry.mls = self.mlsTextField.text;
    } else if (sender == self.nameTextField) {
        self.album.name = self.nameTextField.text;
    } else if (sender == self.descriptionTextField) {
        self.album.albumDescritpion = self.descriptionTextField.text;
    }
}


- (IBAction)saveData:(id)sender {
    if (self.location.sublocation !=nil && self.location.city !=nil && self.location.province != nil) {
        self.album.entry = self.entry;
        self.album.entry.location = self.location;
        [appDelegate.dataWrapper addAlbum:self.album];
        /*[appDelegate.coinsorter createAlbum:self.album callback:^(NSString *album_id) {
            if (self.photoImage != nil) {
                [self.saveFunction saveImageIntoDocument:self.photoImage metadata:metadata album:self.album];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CoverPhotoChange" object:nil];
            }
        }];*/
        [self.navigationController popToRootViewControllerAnimated:NO];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR" message:@"Address or City or State Can't be Empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alert show];
    }
}

-(void) geocodeAddress {
    geocoder = [[CLGeocoder alloc]init];
    [geocoder geocodeAddressString:self.addressTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
        } else {
           CLPlacemark *placemark = [placemarks lastObject];
            [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
            self.location.longitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.longitude];
            self.location.latitude = [NSString stringWithFormat:@"%f", placemark.location.coordinate.latitude];
            self.location.postCode = [placemark.addressDictionary objectForKey:@"ZIP"];
            self.location.country =
            [placemark.addressDictionary objectForKey:@"Country"];
            self.location.countryCode =
            [placemark.addressDictionary objectForKey:@"CountryCode"];
            self.location.city = [placemark.addressDictionary objectForKey:@"City"];
            self.location.province = [placemark.addressDictionary objectForKey:@"State"];
            [self fillLocationData];
        }
    }];
}

- (void)geocodeLocation:(CLLocation *)lac {
    if (!geocoder)
        geocoder = [[CLGeocoder alloc] init];
    
    [geocoder reverseGeocodeLocation:lac
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       if ([placemarks count] > 0) {
                           
                           // get address properties of location
                           CLPlacemark *p = [placemarks lastObject];
                           self.location.postCode = [p.addressDictionary objectForKey:@"ZIP"];
                           self.location.country =
                           [p.addressDictionary objectForKey:@"Country"];
                           self.location.countryCode =
                           [p.addressDictionary objectForKey:@"CountryCode"];
                           self.location.city = [p.addressDictionary objectForKey:@"City"];
                           self.location.sublocation = [p.addressDictionary objectForKey:@"Name"];
                           self.location.province = [p.addressDictionary objectForKey:@"State"];
                          
                       }
                   }];
    [self fillLocationData];
}


-(void) dataMapView:(CSLocation *)newlocation {
    NSLog(@"%@", newlocation.sublocation);
    
    // populate the location object with details from map
    self.location.sublocation = newlocation.sublocation;
    self.location.city = newlocation.city;
    self.location.province = newlocation.province;
    self.location.latitude = newlocation.latitude;
    self.location.longitude = newlocation.longitude;
    self.location.postCode = newlocation.postCode;
    self.location.countryCode = newlocation.countryCode;
    self.location.country = newlocation.country;
    self.location.altitude = newlocation.altitude;
    
    [self fillLocationData];
}
-(void)performSegue {
    [self performSegueWithIdentifier:@"pushSegue" sender:self];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"pushSegue"]) {
        
        // post notification to let details view know not to disable editing
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddNewLocationNotification" object:nil];
        
        AddingLocationViewController *vc = (AddingLocationViewController *)segue.destinationViewController;
        vc.delegate = self;
    }
}
- (void)showPop:(id)sender {
    if (self.popView.visible) {
        self.popView.hidden = YES;
    }
    self.popView = [[SGPopSelectView alloc] init];
    if (sender == self.historySelectBtn) {
        NSArray *locationArray =[appDelegate.dataWrapper getAllAlbums];
        NSMutableArray *name = [[NSMutableArray alloc] init];
        for (CSAlbum *a in locationArray) {
            [name addObject:a.entry.location.sublocation];
        }
        [self.view addSubview:self.popView];
        self.popView.selections = name;
        typeof(self) __weak weakSelf = self;
        self.popView.selectedHandle = ^(NSInteger selectedIndex){
            NSLog(@"selected index %ld, content is %@", selectedIndex,locationArray[selectedIndex]);
            weakSelf.album = [locationArray objectAtIndex:selectedIndex];
            weakSelf.location = weakSelf.album.entry.location;
            weakSelf.entry = weakSelf.album.entry;
            NSLog(@"self locat %@",weakSelf.location.sublocation);
            [weakSelf fillLocationData];
        };
    } else if (sender == self.typeSelectBtn) {
        NSArray *type = @[@"Condominium",@"Commercial",@"Farm",@"House",@"Land",@"Parking",@"Residential",@"Recreational",@"Townhouses"];
        [self.view addSubview:self.popView];
        self.popView.selections = type;
        typeof(self) __weak weakSelf = self;
        self.popView.selectedHandle = ^(NSInteger selectedIndex){
            NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
            [weakSelf.typeLabel setText:[type objectAtIndex:selectedIndex]];
            weakSelf.entry.type = weakSelf.typeLabel.text;
        };
    } else if (sender == self.statusSelectBtn) {
        
        NSArray *type = @[@"For Sale",@"For Rent",@"For Sale Or Rent"];
        [self.view addSubview:self.popView];
        self.popView.selections = type;
        typeof(self) __weak weakSelf = self;
        self.popView.selectedHandle = ^(NSInteger selectedIndex){
            NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
            [weakSelf.statusLabel setText:[type objectAtIndex:selectedIndex]];
            weakSelf.entry.listing = weakSelf.statusLabel.text;
        };
    } else if (sender == self.bedSelectBtn) {
        NSArray *type = @[@"1",@"2",@"3",@"4",@"5",@"6",@"6+"];
        [self.view addSubview:self.popView];
        self.popView.selections = type;
        typeof(self) __weak weakSelf = self;
        self.popView.selectedHandle = ^(NSInteger selectedIndex){
            NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
            [weakSelf.bedLabel setText:[type objectAtIndex:selectedIndex]];
            weakSelf.entry.bed = weakSelf.bedLabel.text;
        };
    } else if (sender == self.bathSelectBtn) {
        NSArray *type = @[@"1",@"2",@"3",@"4",@"5",@"5+"];
        [self.view addSubview:self.popView];
        self.popView.selections = type;
        typeof(self) __weak weakSelf = self;
        self.popView.selectedHandle = ^(NSInteger selectedIndex){
            NSLog(@"selected index %ld, content is %@", selectedIndex,type[selectedIndex]);
            [weakSelf.bathLabel setText:[type objectAtIndex:selectedIndex]];
            weakSelf.entry.bath = weakSelf.bathLabel.text;
        };
    }
    CGPoint p = [self.view center];
    
    [self.popView showFromView:self.view atPoint:p animated:YES];
}

- (NSString *) getPriceText {
    if (editEnabled) {
        return [self.entry.price stringValue];
    } else {
        return [self.entry formatPrice:self.entry.price];
    }
}

-(void) fillLocationData {
    self.addressTextField.text = self.location.sublocation;
    self.cityTextField.text = self.location.city;
    self.countryTextField.text = self.location.country;
    self.stateTextField.text = self.location.province;
    self.postcodeTextField.text = self.location.postCode;
    self.tagTextField.text = self.entry.tag;
    self.priceTextField.text = [self getPriceText];
    self.yearBuiltTextField.text = self.entry.yearBuilt;
    self.buildingSqftTextField.text = [self.entry.buildingSqft stringValue];
    self.landSqftTextField.text = [self.entry.landSqft stringValue];
    self.mlsTextField.text = [self.entry.landSqft stringValue];
    self.typeLabel.text = self.entry.type;
    self.statusLabel.text = self.entry.listing;
    self.bedLabel.text = self.entry.bed;
    self.bathLabel.text = self.entry.bath;
    self.nameTextField.text = self.album.name;
    self.descriptionTextField.text = self.album.albumDescritpion;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.view];
    if (self.popView.visible && CGRectContainsPoint(self.popView.frame, p)) {
        return NO;
    }
    return YES;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 5;
            break;
        case 2:
            return 4;
            break;
        case 3:
            return 6;
            break;
        default:
            return 0;
            break;
    }
    // Return the number of rows in the section.
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
             sectionName = NSLocalizedString(@"Album", @"Album");
            break;
        case 1:
            sectionName = NSLocalizedString(@"Location", @"Location");
            break;
        case 2:
            sectionName = NSLocalizedString(@"Status", @"Status");
            break;
        case 3:
            sectionName = NSLocalizedString(@"Building", @"Building");
            break;
            // ...
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSString *identifier = [NSString stringWithFormat:@"cell%ld",indexPath.row+1];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.section) {
        case 0:
        {
            for (UIView *subviews in cell.contentView.subviews){
                [subviews removeFromSuperview];
            }
            switch (indexPath.row) {
                case 0:
                {
                    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    nameLabel.text = @"Name";
                    [cell.contentView addSubview:nameLabel];
                    
                    self.nameTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.nameTextField.delegate = self;
                    [cell.contentView addSubview:self.nameTextField];
                    break;
                }
                case 1:
                {
                    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    descriptionLabel.text = @"Description";
                    [cell.contentView addSubview:descriptionLabel];
                    
                    self.descriptionTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.descriptionTextField.delegate = self;
                    [cell.contentView addSubview:self.descriptionTextField];
                    break;
                }
                default:
                    break;
            }

        }
            break;
        case 1:
        {
            for (UIView *subviews in cell.contentView.subviews){
                [subviews removeFromSuperview];
            }
            switch (indexPath.row) {
                case 0:
                {
                    UILabel *AddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 70, 30.0)];
                    AddressLabel.text = @"Address";
                    [cell.contentView addSubview:AddressLabel];
                    
                    self.addressTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.addressTextField.adjustsFontSizeToFitWidth = YES;
                    self.addressTextField.delegate = self;
                    [cell.contentView addSubview:self.addressTextField];
                    
                    [cell.contentView addSubview:self.mapAddingBtn];
                }
                    break;
                case 1:
                {
                    UILabel *cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 70, 30.0)];
                    cityLabel.text = @"City";
                    [cell.contentView addSubview:cityLabel];
                    
                    self.cityTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.cityTextField.delegate = self;
                    [cell.contentView addSubview:self.cityTextField];
                    
                    [cell.contentView addSubview:self.historySelectBtn];
                }
                    break;
                case 2:
                {
                    
                    UILabel *stateLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 70, 30.0)];
                    stateLabel.text = @"State";
                    [cell.contentView addSubview:stateLabel];
                    
                    
                    self.stateTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.stateTextField.delegate = self;
                    [cell.contentView addSubview:self.stateTextField];
                }
                    break;
                case 3:
                {
                    UILabel *countryLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 70, 30.0)];
                    countryLabel.text = @"Country";
                    
                    [cell.contentView addSubview:countryLabel];
                    
                    self.countryTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.countryTextField.delegate = self;
                    [cell.contentView addSubview:self.countryTextField];
                    break;
                }
                case 4:
                {
                    UILabel *postalLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    postalLabel.text = @"ZIP";
                    
                    [cell.contentView addSubview:postalLabel];
                    
                    self.postcodeTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.postcodeTextField.delegate = self;
                    [cell.contentView addSubview:self.postcodeTextField];
                    break;
                }
                default:
                    break;
            }
            
        }
            break;
        case 2:
        {
            for (UIView *subviews in cell.contentView.subviews){
                [subviews removeFromSuperview];
            }
            switch (indexPath.row) {
                case 3:
                {
                    UILabel *tagLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    tagLabel.text = @"Tag";
                    
                    [cell.contentView addSubview:tagLabel];
                    
                    self.tagTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.tagTextField.delegate = self;
                    [cell.contentView addSubview:self.tagTextField];
                    break;
                }
                case 0:
                {
                    UILabel *priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    priceLabel.text = @"Price";
                    
                    [cell.contentView addSubview:priceLabel];
                    
                    self.priceTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.priceTextField.keyboardType = UIKeyboardTypeNumberPad;
                    self.priceTextField.delegate = self;
                    [cell.contentView addSubview:self.priceTextField];
                    break;
                }
                case 1:
                {
                    UILabel *type = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    type.text = @"Type";
                    
                    [cell.contentView addSubview:type];
                    
                    [cell.contentView addSubview:self.typeLabel];
                    
                    [cell.contentView addSubview:self.typeSelectBtn];
                    break;
                }
                case 2:
                {
                    UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    status.text = @"Listing";
                    
                    [cell.contentView addSubview:status];
                    
                    [cell.contentView addSubview:self.statusLabel];
                    
                    [cell.contentView addSubview:self.statusSelectBtn];
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case 3:
        {
            for (UIView *subviews in cell.contentView.subviews){
                [subviews removeFromSuperview];
            }
            switch (indexPath.row) {
                case 0:
                {
                    UILabel *yearBuilt = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    yearBuilt.text = @"Year Built";
                    
                    [cell.contentView addSubview:yearBuilt];
                    
                    self.yearBuiltTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.yearBuiltTextField.keyboardType = UIKeyboardTypeNumberPad;
                    self.yearBuiltTextField.delegate = self;
                    [cell.contentView addSubview:self.yearBuiltTextField];
                    break;
                }
                case 1:
                {
                    UILabel *bed = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    bed.text = @"Bedroom";
                    
                    [cell.contentView addSubview:bed];
                    
                    [cell.contentView addSubview:self.bedLabel];
                    
                    [cell.contentView addSubview:self.bedSelectBtn];
                    break;
                }
                case 2:
                {
                    UILabel *bath = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 90, 30.0)];
                    bath.text = @"Bathroom";
                    
                    [cell.contentView addSubview:bath];
                    
                    [cell.contentView addSubview:self.bathLabel];
                    
                    [cell.contentView addSubview:self.bathSelectBtn];
                    break;
                }
                case 3:
                {
                    UILabel *buildSqft = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    buildSqft.text = @"Floor Size";
                    
                    [cell.contentView addSubview:buildSqft];
                    
                    self.buildingSqftTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.buildingSqftTextField.keyboardType = UIKeyboardTypeNumberPad;
                    self.buildingSqftTextField.delegate = self;
                    [cell.contentView addSubview:self.buildingSqftTextField];
                    break;
                }
                case 4:
                {
                    UILabel *landSqft = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    landSqft.text = @"Lot Size";
                    
                    [cell.contentView addSubview:landSqft];
                    
                    self.landSqftTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.landSqftTextField.keyboardType = UIKeyboardTypeNumberPad;
                    self.landSqftTextField.delegate = self;
                    [cell.contentView addSubview:self.landSqftTextField];
                    break;
                }
                case 5:
                {
                    UILabel *mls = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 110, 30.0)];
                    mls.text = @"MLS #";
                    
                    [cell.contentView addSubview:mls];
                    
                    self.mlsTextField.borderStyle = UITextBorderStyleRoundedRect;
                    self.mlsTextField.keyboardType = UIKeyboardTypeNumberPad;
                    self.mlsTextField.delegate = self;
                    [cell.contentView addSubview:self.mlsTextField];
                    break;
                }
                default:
                    break;
            }
        }
        default:
            break;
            
    }
    
    return cell;
    // Configure the cell...
}

- (UILabel *) createLabel: (NSString *) text frame: (CGRect) frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label setText:text];
    //  [label setFont:[UIFont]]
    
    
    return label;
}

-(void) createViewContent {
    self.mapAddingBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.mapAddingBtn addTarget:self action:@selector(performSegue) forControlEvents:UIControlEventTouchUpInside];
    [self.mapAddingBtn setImage:[UIImage imageNamed:@"earth-america-7.png"] forState:UIControlStateNormal];
    
    self.historySelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.historySelectBtn addTarget:self action:@selector(showPop:) forControlEvents:UIControlEventTouchUpInside];
    [self.historySelectBtn setImage:[UIImage imageNamed:@"book-cover-plus-7.png"] forState:UIControlStateNormal];
    
    self.typeSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.typeSelectBtn addTarget:self action:@selector(showPop:) forControlEvents:UIControlEventTouchUpInside];
    [self.typeSelectBtn setImage:[UIImage imageNamed:@"book-cover-plus-7.png"] forState:UIControlStateNormal];
    
    self.statusSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.statusSelectBtn addTarget:self action:@selector(showPop:) forControlEvents:UIControlEventTouchUpInside];
    [self.statusSelectBtn setImage:[UIImage imageNamed:@"book-cover-plus-7.png"] forState:UIControlStateNormal];
    
    self.bedSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.bedSelectBtn addTarget:self action:@selector(showPop:) forControlEvents:UIControlEventTouchUpInside];
    [self.bedSelectBtn setImage:[UIImage imageNamed:@"book-cover-plus-7.png"] forState:UIControlStateNormal];
    
    self.bathSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(252, 9, 60, 30)];
    [self.bathSelectBtn addTarget:self action:@selector(showPop:) forControlEvents:UIControlEventTouchUpInside];
    [self.bathSelectBtn setImage:[UIImage imageNamed:@"book-cover-plus-7.png"] forState:UIControlStateNormal];
    
    self.addressTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.addressTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 150, 30.0)];
    [self.nameTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.descriptionTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 150, 30.0)];
    [self.descriptionTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.cityTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.cityTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.stateTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.stateTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.countryTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.countryTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.postcodeTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.postcodeTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.tagTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.tagTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.priceTextField = [[UITextField alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    [self.priceTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(85, 9, 150, 30.0)];
    self.yearBuiltTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 115, 30.0)];
    [self.yearBuiltTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.bedLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 9, 150, 30.0)];
    self.bathLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 9, 150, 30.0)];
    self.buildingSqftTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 115, 30.0)];
    [self.buildingSqftTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.landSqftTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 115, 30.0)];
    [self.landSqftTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
    
    self.mlsTextField = [[UITextField alloc] initWithFrame:CGRectMake(120, 9, 115, 30.0)];
    [self.mlsTextField addTarget:self action:@selector(textFieldValueChanged:) forControlEvents:UIControlEventAllEditingEvents];
}


-(void)addToolBarOnKeyboard {
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad:)],
                           nil];
    [numberToolbar sizeToFit];
    self.priceTextField.inputAccessoryView = numberToolbar;
    self.yearBuiltTextField.inputAccessoryView = numberToolbar;
    self.buildingSqftTextField.inputAccessoryView = numberToolbar;
    self.landSqftTextField.inputAccessoryView = numberToolbar;
    self.mlsTextField.inputAccessoryView = numberToolbar;
    
}

-(void)doneWithNumberPad:(id) sender{
 
    [self.priceTextField resignFirstResponder];
    [self.yearBuiltTextField resignFirstResponder];
    [self.buildingSqftTextField resignFirstResponder];
    [self.landSqftTextField resignFirstResponder];
    [self.mlsTextField resignFirstResponder];
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
