//
//  ViewController.m
//  fliklr
//
//  Created by gérald m on 05/02/2016.
//  Copyright © 2016 gérald m. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
// ici les variables sont considérées privées
{
    NSMutableArray* photoTitles;
    NSMutableArray* photoSmallImageUri;
    NSMutableArray* photoLargeImageUri;
    NSMutableDictionary* photoSmallImageCache;
}
@end
// ici les variables sont considérées globales
NSMutableData* _receivedData;
bool bigViewHidden = YES;
long bigImageIndex;


@implementation ViewController

-(void)viewWillAppear:(BOOL)animated{
    self.blurView.hidden = YES;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    photoTitles = [NSMutableArray new];
    photoSmallImageUri = [NSMutableArray new];
    photoLargeImageUri = [NSMutableArray new];
    photoSmallImageCache = [NSMutableDictionary new];
    
    
    //ajout des delegate
    [self.tableView setDelegate:self];
    [self.searchBar setDelegate:self];
    self.tableView.dataSource = self;
    
    // init clic on big image to hide it
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideBigImage)];
    singleTap.numberOfTapsRequired = 1;
    [self.bigView setUserInteractionEnabled:YES];
    [self.bigView addGestureRecognizer:singleTap];
    
}

// delegate qui sert à gérer les réponses depuis l'url
// etape 1 : on a la réponse
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    if (!_receivedData)
    {
        _receivedData = [NSMutableData new];
    }
    [_receivedData setLength:0];
    NSLog(@"didReceiveResponse : responseData length(%lu)",_receivedData.length);
}

//etape 2 : on recoit des donnnées
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [_receivedData appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"Error while receiving data... Error %@ %@",[error localizedDescription],[[error userInfo] objectForKey:NSURLErrorFailingURLErrorKey]);
}

//etape 3 : la réception des données est terminée
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"Succeeded ! Received %lu bytes of data",_receivedData.length);
    
    NSString *stringData = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
    NSError *error;
    
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:&error];
    if (json)
    {
        NSLog(@"Json parsing OK");
    }
    else
    {
        NSLog(@"Json parsing failed");
    }
    
    NSArray *photos = json[@"photos"][@"photo"];
    
    
    
    
    
    // Loop through each entry in the dictionary...
    for (NSDictionary *photo in photos)
    {
        // Get title of the image
        NSString *title = photo [@"title"];
        
        // Save the title to the photo titles array
        [photoTitles addObject:(title.length > 0 ? title : @"Untitled")];
    }
    
    
    // on charge de maniere asynchrone les photos
    
    
    
    for (NSDictionary *photo in photos){
        
        NSString *photoURLString =
        [NSString stringWithFormat:@"https://farm%@.static.flickr.com/%@/%@_%@_s.jpg",
         [photo objectForKey:@"farm"], [photo objectForKey:@"server"],
         [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
        
        
        // The performance (scrolling) of the table will be much better if we
        // build an array of the image data here, and then add this data as
        // the cell.image value (see cellForRowAtIndexPath:)
        [photoSmallImageUri addObject:[NSURL URLWithString:photoURLString]];
        
        // Build and save the URL to the large image so we can zoom
        // in on the image if requested
        photoURLString =
        [NSString stringWithFormat:@"https://farm%@.static.flickr.com/%@/%@_%@.jpg",
         [photo objectForKey:@"farm"], [photo objectForKey:@"server"],
         [photo objectForKey:@"id"], [photo objectForKey:@"secret"]];
        
        [photoLargeImageUri addObject:[NSURL URLWithString:photoURLString]];
    }
    
    
    
    
    // on reload le tableau
    [self.tableView reloadData];
    
}

// agrandir l'image quand on clic sur une ligne
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self showBigImage:YES fromUrl:[photoLargeImageUri objectAtIndex:indexPath.row]];
    
    bigImageIndex = indexPath.row;
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    //Return the number of sections.
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //retourne nombre de lignes dans chaque section
    return photoTitles.count;
}

//titre des sections
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Résultats";
}


// renvoie la taille des cellules selon le type de personne
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 82;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [photoTitles objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = @"";
    
    // on crée une image blanche
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(75,75), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    cell.imageView.image = blank;
    
    // on crée la marguerite
    cell.accessoryType = UITableViewCellAccessoryNone;
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicatorView startAnimating];
    cell.accessoryView = activityIndicatorView;
    
    
    
    
    // on vérifie si le cache existe
    if ([photoSmallImageCache objectForKey:[NSString stringWithFormat:@"%lu",indexPath.row]])
    {
        CFTimeInterval startTime = CACurrentMediaTime();
        
        cell.imageView.image = [photoSmallImageCache objectForKey:[NSString stringWithFormat:@"%lu",indexPath.row]];
        
        
        float duration = 1000 * (CACurrentMediaTime() - startTime);
        
        NSLog(@"Image at index %lu loaded from cache in %.03f ms",indexPath.row,duration);
        
        // on retire la marguerite
        cell.accessoryView = nil;
        
        
    }
    
    else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // on charge l'image en fond
            
            
            NSData* imageData = [NSData dataWithContentsOfURL:[photoSmallImageUri objectAtIndex:indexPath.row]];
            
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                
                
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell){
                    CFTimeInterval startTime = CACurrentMediaTime();
                    
                    
                    cell.imageView.image = [UIImage imageWithData:imageData];
                    // save in cache
                    [photoSmallImageCache setObject:cell.imageView.image forKey:[NSString stringWithFormat:@"%lu",indexPath.row]];
                    
                    // remove loading indicator
                    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[cell.imageView viewWithTag:@"indicator"];
                    [indicator removeFromSuperview];
                    
                    cell.setNeedsDisplay;
                    
                    float duration = 1000 * (CACurrentMediaTime() - startTime);
                    
                    // on retire la marguerite
                    cell.accessoryView = nil;
                    
                    NSLog(@"Image at index %lu loaded from internet in %.03f ms",indexPath.row,duration);
                }
            });
            
        });
    }
    return cell;
}
#pragma mark big view

- (void)hideBigImage{
    
    [self showBigImage:NO fromUrl:NULL];
}


-(void)showBigImage:(BOOL)yesNo fromUrl:(NSURL *)url{
    if (yesNo)
    {
        self.bigView.image = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            // on charge l'image en fond
            
            
            NSData* imageData = [NSData dataWithContentsOfURL:url];
            
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                self.bigView.image = [UIImage imageWithData:imageData];
                bigViewHidden = NO;
                self.blurView.alpha = 0.0f;
                self.bigView.alpha = 0.0f;
                self.blurView.hidden = NO;
                
                
                [UIView transitionWithView:self.bigView duration:1.0 options:UIViewAnimationOptionTransitionNone animations: ^ {
                    
                    self.blurView.alpha=1.0f;
                    self.bigView.alpha=1.0f;
                } completion:nil];
                
            });
            
        });
        
        
    }
    else
    {
        self.blurView.alpha = 1.0f;
        self.bigView.alpha = 1.0f;
        
        self.blurView.hidden = NO;
        
        
        [UIView transitionWithView:self.bigView duration:0.5 options:UIViewAnimationOptionTransitionNone animations: ^ {
            
            self.blurView.alpha=0.0f;
            self.bigView.alpha=0.0f;
        } completion:^(BOOL finished){self.blurView.hidden=YES;}];
        
        
        bigViewHidden = YES;
        //scale to base scale
        self.bigView.transform = CGAffineTransformMakeScale(1, 1);
        
        //rotate
        self.bigView.transform = CGAffineTransformMakeRotation(0);
    }
}


#pragma mark searchbar
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"Cancel");
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSLog(@"OK");
    [self getPhotos:searchBar.text];
}


#pragma mark gesture
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

- (IBAction)rotatedOrScaled:(UIGestureRecognizer *)sender {
    
    
    // Get the location of the gesture
    CGPoint location = [self.rotationGestureRecognizer locationInView:self.view];
    
    // Set the rotation angle of the image view to
    // match the rotation of the gesture and the scale to combine 2 operations
    CGAffineTransform transform = CGAffineTransformMakeRotation([self.rotationGestureRecognizer rotation]);
    
    transform = CGAffineTransformScale(transform,self.pinchGestureRecognizer.scale,self.pinchGestureRecognizer.scale);
    
    self.bigView.transform = transform;
    
    if (sender.state==UIGestureRecognizerStateEnded)
    {
        NSLog(@"Gesture finished");
        [UIView transitionWithView:self.bigView duration:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations: ^ {
            
            CGAffineTransform transform = CGAffineTransformMakeScale(1, 1);
            transform = CGAffineTransformRotate(transform,0);
            
            self.bigView.transform = transform;
            
            
        } completion:nil];
        
    }
}


- (IBAction)onSwipe:(UISwipeGestureRecognizer *)sender {
    
    CGPoint location = [sender locationInView:self.view];
    
    if(sender.state==UIGestureRecognizerStateEnded)
    {
        
        switch (sender.direction)
        {
            case UISwipeGestureRecognizerDirectionLeft:
                
                NSLog(@"Swipe left finished");
                [self slideLeftBigImage];
                
                
                
                break;
            case UISwipeGestureRecognizerDirectionRight:
                NSLog(@"Swipe right finished");
                [self slideRightBigImage];
                
                
                break;
            default:break;
        }
        
        
    }
}


-(void)getPhotos:(NSString*)search{
    // Do any additional setup after loading the view, typically from a nib.
    
    // Reseting enventual Arrays
    photoTitles = [NSMutableArray new];
    photoSmallImageUri = [NSMutableArray new];
    photoLargeImageUri = [NSMutableArray new];
    photoSmallImageCache = [NSMutableDictionary new];
    
    NSString*       tag=search;
    NSURL*          flickrGetURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.flickr.com/services/rest/?method=flickr.photos.search&tags=%@&safe_search=1&per_page=2000&format=json&nojsoncallback=1&api_key=efb4fd5e04fb8f0726fbb75c02782023",tag]];
    
    NSURLRequest*   theRequest = [NSURLRequest requestWithURL:flickrGetURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    NSURLConnection *con = [[NSURLConnection alloc]initWithRequest:theRequest delegate:self];
}

#pragma mark animations
-(void)slideLeftBigImage{
    if (bigImageIndex<photoTitles.count-1){
        
        bigImageIndex++;
        
        
        [UIView             transitionWithView:self.bigView duration:0.6
                                       options:UIViewAnimationOptionTransitionNone
                                    animations: ^ {
                                        CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                        CGAffineTransform transform = CGAffineTransformMakeTranslation(-width,0);
                                        self.bigView.transform = transform;
                                    }
                                    completion:^(BOOL finished){
                                        
                                        [UIView             transitionWithView:self.bigView duration:0
                                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                                    animations: ^ {
                                                                        CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                                                        CGAffineTransform transform = CGAffineTransformMakeTranslation(width,0);
                                                                        self.bigView.transform = transform;
                                                                    }
                                         
                                                                    completion:^(BOOL finished){
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            
                                                                            // on charge l'image en fond
                                                                            
                                                                            NSURL *url = [photoLargeImageUri objectAtIndex:bigImageIndex];
                                                                            NSData* imageData = [NSData dataWithContentsOfURL:url];
                                                                            
                                                                            
                                                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                                                                
                                                                                
                                                                                self.bigView.image = [UIImage imageWithData:imageData];
                                                                                [UIView             transitionWithView:self.bigView duration:1.0
                                                                                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                                            animations: ^ {
                                                                                                                CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                                                                                                CGAffineTransform transform = CGAffineTransformMakeTranslation(0,0);
                                                                                                                self.bigView.transform = transform;
                                                                                                            }
                                                                                                            completion:nil];
                                                                                
                                                                            });
                                                                            
                                                                        });
                                                                        
                                                                        
                                                                    }
                                         
                                         
                                         ];
                                    }];
    }
}

-(void)slideRightBigImage{
    
    if (bigImageIndex>0){
        
        bigImageIndex--;
        
        
        [UIView             transitionWithView:self.bigView duration:0.6
                                       options:UIViewAnimationOptionTransitionNone
                                    animations: ^ {
                                        CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                        CGAffineTransform transform = CGAffineTransformMakeTranslation(width,0);
                                        self.bigView.transform = transform;
                                    }
                                    completion:^(BOOL finished){
                                        
                                        [UIView             transitionWithView:self.bigView duration:0
                                                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                                                    animations: ^ {
                                                                        CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                                                        CGAffineTransform transform = CGAffineTransformMakeTranslation(-width,0);
                                                                        self.bigView.transform = transform;
                                                                    }
                                                                    completion:^(BOOL finished){
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            
                                                                            // on charge l'image en fond
                                                                            
                                                                            NSURL *url = [photoLargeImageUri objectAtIndex:bigImageIndex];
                                                                            NSData* imageData = [NSData dataWithContentsOfURL:url];
                                                                            
                                                                            
                                                                            dispatch_sync(dispatch_get_main_queue(), ^{
                                                                                
                                                                                
                                                                                self.bigView.image = [UIImage imageWithData:imageData];
                                                                                [UIView             transitionWithView:self.bigView duration:1.0
                                                                                                               options:UIViewAnimationOptionTransitionCrossDissolve
                                                                                                            animations: ^ {
                                                                                                                CGFloat width = [UIScreen mainScreen].bounds.size.width;
                                                                                                                CGAffineTransform transform = CGAffineTransformMakeTranslation(0,0);
                                                                                                                self.bigView.transform = transform;
                                                                                                            }
                                                                                                            completion:nil];
                                                                                
                                                                            });
                                                                            
                                                                        });
                                                                        
                                                                        
                                                                    }
                                         
                                         
                                         ];
                                    }];
    }}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
