//
//  ViewController.h
//  fliklr
//
//  Created by gérald m on 05/02/2016.
//  Copyright © 2016 gérald m. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLConnectionDataDelegate,UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *bigView;
@property (weak, nonatomic) IBOutlet UIView *blurView;
@property (strong, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) IBOutlet UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeLeftGestureRecognizer;
@property (strong, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeRightGestureRecognizer;


- (IBAction)rotatedOrScaled:(UIGestureRecognizer *)sender;
- (IBAction)onSwipe:(UISwipeGestureRecognizer *)sender;

-(void)getPhotos:(NSString*)search;
-(void)showBigImage:(BOOL)yesNo fromUrl:(NSURL *)url;
-(void)hideBigImage;
-(void)slideLeftBigImage;
-(void)slideRightBigImage;




@end

