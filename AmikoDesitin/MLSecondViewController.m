/*
 
 Copyright (c) 2013 Max Lungarella <cybrmx@gmail.com>
 
 Created on 11/08/2013.
 
 This file is part of AmiKoDesitin.
 
 AmiKoDesitin is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLSecondViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "MLConstants.h"
#import "SWRevealViewController.h"
#import "MLSearchWebView.h"
#import "MLMedication.h"
//#import "MLMenuViewController.h"
#import "MLViewController.h"

#import "MLAlertView.h"

#import "WebViewJavascriptBridge.h"

typedef NS_ENUM(NSInteger, FindPanelVisibility) {
    FIND_PANEL_INVISIBLE,
    FIND_PANEL_VISIBLE,
    FIND_PANEL_UNDEFINED
};

#pragma mark - Class extension
////////////////////////////////////////////////////////////////////////////////
@interface MLSecondViewController ()
@property WebViewJavascriptBridge *jsBridge;
@end

#pragma mark -
////////////////////////////////////////////////////////////////////////////////
@implementation MLSecondViewController
{
    int mNumRevealButtons;
    int mTotalHighlights;
    int mCurrentHightlight;
    float mFramePosA;
    float mFramePosB;
    FindPanelVisibility mIsFindPanelVisible;
    NSString *mTitle;
    NSString *mCurrentSearch;
}

@synthesize searchField;
@synthesize webView;
@synthesize findCounter;
@synthesize findPanel;
@synthesize htmlStr;
@synthesize medBasket;
@synthesize titleViewController;
//@synthesize anchor;
@synthesize keyword;

- (void) dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif

    htmlAnchor = nil;    
    searchField = nil;
    htmlStr = nil;
    medBasket = nil;
    
    self.webView.delegate = nil;
    self.webView = nil;
    [self.webView removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil
                          bundle:(NSBundle *)nibBundleOrNil
                           title:(NSString *)title
                        andParam:(int)numRevealButtons
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    mCurrentSearch = @"";
    [self resetSearchField];
    
    mNumRevealButtons = numRevealButtons;
    mTitle = title;
    
    mIsFindPanelVisible = FIND_PANEL_UNDEFINED;
    
    return self;
}

- (instancetype) initWithNibName: (NSString *)nibNameOrNil
                          bundle: (NSBundle *)nibBundleOrNil
                      withString: (NSString *)html
{
    self = [super init];

    mCurrentSearch = @"";
    [self resetSearchField];

    htmlStr = [[NSString alloc] initWithString:html];
    
    return self;
}

#pragma mark - IBAction methods

- (IBAction) moveToPrevHighlight:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s line %d, mTotalHighlights: %d, mCurrentHightlight: %d", __FUNCTION__, __LINE__,
          mTotalHighlights, mCurrentHightlight);
#endif
    if (mTotalHighlights <= 1)
        return;

    mCurrentHightlight--;
    if (mCurrentHightlight < 0)
        mCurrentHightlight = mTotalHighlights-1;

    [self.webView nextHighlight:mCurrentHightlight];
    [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
}

- (IBAction) moveToNextHighlight:(id)sender
{
#ifdef DEBUG
    NSLog(@"%s line %d, mTotalHighlights: %d, mCurrentHightlight: %d", __FUNCTION__, __LINE__,
          mTotalHighlights, mCurrentHightlight);
#endif
    if (mTotalHighlights <= 1) {
        // TODO: make sure findPanel is hidden
        return;
    }

    mCurrentHightlight++;
    if (mCurrentHightlight >= mTotalHighlights)
        mCurrentHightlight = 0;

    [self.webView nextHighlight:mCurrentHightlight];
    [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
}

- (void) resetSearchField
{
#ifdef DEBUG
    NSLog(@"%s line %d, mCurrentSearch: <%@>", __FUNCTION__, __LINE__, mCurrentSearch);
#endif
    if (mCurrentSearch)
        [searchField setText:mCurrentSearch];
    else
        [searchField setText:@""];
    
    if ([self.htmlStr isEqualToString:@"Interactions"])
        [searchField setPlaceholder:[NSString stringWithFormat:NSLocalizedString(@"Search in interactions", nil)]];
    else
        [searchField setPlaceholder:[NSString stringWithFormat:NSLocalizedString(@"Search in technical info", nil)]];
    
    if ([mTitle isEqualToString:@"About"])
        [searchField setPlaceholder:NSLocalizedString(@"Search in report", nil)];
}

/** 
 Creates find counter label which is located in the searchfield
 */
- (UILabel *) findCounterAtPos:(float)x andSize:(float)size
{
    UILabel *findCnt = [[UILabel alloc] initWithFrame:CGRectMake(x, 0.0, 60.0, size)];
    findCnt.font = [UIFont systemFontOfSize:14];
    findCnt.textColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
  
    return findCnt;
}

/**
 This is the observing class
 */
- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context
{
#ifdef DEBUG
    NSLog(@"%s line %d, keyPath: %@, change:%@", __FUNCTION__, __LINE__, keyPath, change);
#endif
    // [self addObserver:self forKeyPath:@"javaScript" options:0 context:@"javaScriptChanged"];
    // This class is added as an observer in '[MLViewController switchToAipsView]'
    if ([keyPath isEqualToString:@"javaScript"]) {
        htmlAnchor = [NSString stringWithString:[change objectForKey:@"new"]];
        [self.webView stopLoading];
        [self.webView stringByEvaluatingJavaScriptFromString:htmlAnchor];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -

- (void) viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s, htmlStr length: %lu", __FUNCTION__, (unsigned long)[htmlStr length]);
#endif
    
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        }
        else {
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        }

        self.edgesForExtendedLayout = UIRectEdgeNone;
#if 0 // @@@
        searchField.barTintColor = [UIColor systemGray3Color];
#endif
        searchField.translucent = YES;
    } // iPad

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (orientation == UIInterfaceOrientationLandscapeLeft ||
            orientation == UIInterfaceOrientationLandscapeRight)
        {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 32.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 32.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:searchField];
            
            // For iPhones add findCounter manually
#ifdef DEBUG
            NSLog(@"%s %d, mCurrentHightlight: %d/%d", __FUNCTION__, __LINE__, mCurrentHightlight, mTotalHighlights);
#endif
            self.findCounter = [self findCounterAtPos:250.0 andSize:32.0];
            [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
            [searchBarView addSubview:self.findCounter];
            
            self.navigationItem.titleView = searchBarView;
            //
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthLandscape];

            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
        }
        else {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:searchField];
            
            // For iPhones add findCounter manually
#ifdef DEBUG
            NSLog(@"%s %d, mCurrentHightlight: %d/%d", __FUNCTION__, __LINE__, mCurrentHightlight, mTotalHighlights);
#endif
            self.findCounter = [self findCounterAtPos:200.0 andSize:44.0];
            [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
            [searchBarView addSubview:self.findCounter];
            
            self.navigationItem.titleView = searchBarView;
            //
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthPortrait];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawPortrait];
        }

        self.edgesForExtendedLayout = UIRectEdgeNone;
#if 0 // @@@
        searchField.barTintColor = [UIColor clearColor]; //[UIColor colorWithWhite:0.9 alpha:0.0];
#endif
        searchField.backgroundImage = [UIImage new];
        searchField.translucent = YES;
    } // iPhone
    
    mCurrentSearch = @"";
    // Reset search field place holder
    [self resetSearchField];
    
    // Update webview which is either "Fachinfo" or "medication basket"
    if (self.htmlStr)
        [self updateWebView];
    
    // Create objc - js bridge
    [self createJSBridge];
}

- (void) viewDidAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
//    for (id gr in self.view.gestureRecognizers)
//        NSLog(@"gestureRecognizer: %@", [gr class]);
#endif
    
    [super viewDidAppear:animated];
    
    [self.webView reload];
    
    self.findPanel.layer.cornerRadius = 6.0f;
    
    [self.findPanel setHidden:YES];
    [self.findCounter setHidden:YES];
    
    mFramePosA = self.findPanel.frame.origin.y;
    mFramePosB = self.findPanel.frame.origin.y - 200;
    
    if ([keyword length] > 0)
        [self.searchField setText:keyword];
}

- (void) viewDidLoad
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
//    for (id gr in self.view.gestureRecognizers)
//        NSLog(@"gestureRecognizer: %@", [gr class]);
#endif
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    self.title = mTitle;

    // SWRevealViewController extends UIViewController!
    SWRevealViewController *revealController = [self revealViewController];
    
    [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
#if 0 // @@@
    self.navigationController.navigationBar.backgroundColor = VERY_LIGHT_GRAY_COLOR;// MAIN_TINT_COLOR;
    self.navigationController.navigationBar.barTintColor = VERY_LIGHT_GRAY_COLOR;
#endif
    self.navigationController.navigationBar.translucent = NO;
    
    {
        UIBarButtonItem *revealButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStylePlain
                                        target:revealController
                                        action:@selector(revealToggle:)];
        self.navigationItem.leftBarButtonItem = revealButtonItem;
    }
    
    if ( mNumRevealButtons == 2 )
    {
        UIBarButtonItem *rightRevealButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reveal-icon.png"]
                                         style:UIBarButtonItemStylePlain
                                        target:revealController
                                        action:@selector(rightRevealToggle:)];
        self.navigationItem.rightBarButtonItem = rightRevealButtonItem;
    }
    
    // PanGestureRecognizer goes here ... could be also placed in the other Views but this is the main view!
    // [self.navigationController.navigationBar addGestureRecognizer:revealController.panGestureRecognizer];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
#if 0 // @@@
        searchField.barTintColor = [UIColor systemGray3Color];
        searchField.backgroundColor = [UIColor clearColor];
#endif
        searchField.translucent = YES;
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        // Add search bar as title view to navigation bar
        searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchField.barStyle = UIBarStyleDefault;
#if 0 // @@@
        searchField.barTintColor = [UIColor clearColor];
#endif
        searchField.backgroundImage = [UIImage new];
#if 0 // @@@
        searchField.backgroundColor = [UIColor clearColor];
        searchField.tintColor = [UIColor systemGray3Color];    // cursor color
#endif
        searchField.translucent = YES;
        searchField.delegate = self;
        
        UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        // searchBarView.autoresizingMask = 0;
        [searchBarView addSubview:searchField];
        
        self.navigationItem.titleView = searchBarView;
    }
    
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIGestureRecognizer *tapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(handleSingleTap:)];
        tapper.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:tapper];
    }
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
 
    NSLog(@"%s", __FUNCTION__);
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark -

/**
 Removes keyboard on iPhones
 */
- (void) handleSingleTap:(UITapGestureRecognizer *)sender
{
    [searchField resignFirstResponder];
}

//- (void) viewDidUnload
//{
//    self.webView = nil;
//}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// TODO: Implement 'viewWillTransitionToSize:withTransitionCoordinator:' instead
- (void) willRotateToInterfaceOrientation: (UIInterfaceOrientation)toInterfaceOrientation
                                 duration: (NSTimeInterval)duration
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Landscape_iPad;
        else
            self.revealViewController.rearViewRevealWidth = RearViewRevealWidth_Portrait_iPad;
        
#if 0 // @@@
        searchField.barTintColor = [UIColor systemGray3Color];
        searchField.backgroundColor = [UIColor clearColor];
#endif
        searchField.translucent = YES;
    }

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
            toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)
        {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 32.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 32.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:self.searchField];
            
            // For iPhones add findCounter manually
            self.findCounter = [self findCounterAtPos:250.0 andSize:32.0];
            if (mTotalHighlights>0)
                [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
            [searchBarView addSubview:self.findCounter];
            
            self.navigationItem.titleView = searchBarView;
            //            
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthLandscape];
            self.revealViewController.rearViewRevealOverdraw = [MLConstants rearViewRevealOverdrawLandscape];

            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationSlide];
        }
        else {
            // Add search bar as title view to navigation bar
            self.searchField = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            self.searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            UIView *searchBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
            searchBarView.autoresizingMask = 0;
            self.searchField.delegate = self;
            [searchBarView addSubview:self.searchField];
            
            // For iPhones add findCounter manually
            self.findCounter = [self findCounterAtPos:200.0 andSize:44.0];
            if (mTotalHighlights>0)
                [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
             [searchBarView addSubview:self.findCounter];
            
            self.navigationItem.titleView = searchBarView;
            //
            self.revealViewController.rearViewRevealWidth = [MLConstants rearViewRevealWidthPortrait];

            // Shows status bar
            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationSlide];
        }

        // Sets colors in toolbar and searchfield - modify with care!
        searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchField.barStyle = UIBarStyleDefault;
#if 0 // @@@
        searchField.barTintColor = [UIColor clearColor];
#endif
        searchField.backgroundImage = [UIImage new];
#if 0 // @@@
        searchField.backgroundColor = [UIColor clearColor];
        searchField.tintColor = [UIColor systemGray3Color];    // cursor color
#endif
        searchField.translucent = YES;
    }

    [self resetSearchField];
}

/**
 The following function intercepts messages sent from javascript to objective C and acts
 acts as a bridge between JS and ObjC
 */
- (void) createJSBridge
{
    if (_jsBridge)
        return;
    
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    [WebViewJavascriptBridge enableLogging];
    
    // @maxl: note the webviewdelegate parameter. if it's not passed, no way to get the webview delegates to work!
    // _jsBridge = [WebViewJavascriptBridge bridgeForWebView:self.webView handler:^(id msg, WVJBResponseCallback responseCallback) {
    _jsBridge = [WebViewJavascriptBridge bridgeForWebView: webView
                                          webViewDelegate: self
                                                  handler: ^(id msg, WVJBResponseCallback responseCallback) {
        if ([msg isEqualToString:@"notify_interaction"]) {
#ifdef DEBUG
            NSLog(@"%s line %d, Notify interaction", __FUNCTION__, __LINE__);
#endif
            [self sendEmailTo:@"zdavatz@ywesee.com"
                  withSubject:[NSString stringWithFormat:@"%@: Unbekannte Interaktionen", APP_NAME]];
        }
        else if ([msg isEqualToString:@"delete_all"]) {
#ifdef DEBUG
            NSLog(@"%s line %d, Delete all", __FUNCTION__, __LINE__);
#endif
            [self.medBasket removeAllObjects];
            [self updateInteractionBasketView];
        }
        else {
#ifdef DEBUG
            NSLog(@"%s line %d, Delete number %@", __FUNCTION__, __LINE__, msg);
#endif
            [self.medBasket removeObjectForKey:msg];
            [self updateInteractionBasketView];
        }
    }];
}

- (void) sendEmailTo:(NSString *)recipient withSubject:(NSString *)subject
{
    // Check if device is configured to send email
    if ([MFMailComposeViewController canSendMail]) {
        // Init mail view controller
        MFMailComposeViewController *mailer = [MFMailComposeViewController new];
        mailer.mailComposeDelegate = self;
        
        // Subject
        [mailer setSubject:subject];
        // Recipient
        if (![recipient isEqualToString:@""]) {
            NSArray *toRecipients = [NSArray arrayWithObjects:recipient, nil];
            [mailer setToRecipients:toRecipients];
        }
        // Attach screenshot...
        // UIImage *screenShot = [UIImage imageNamed:@"Default.png"];
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [UIScreen mainScreen].scale);
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
        UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *imageData = UIImagePNGRepresentation(screenShot);
        
        [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"Images"];

        // It's important to use the presenting root view controller...
        UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        [presentingController presentViewController:mailer animated:YES completion:nil];
    }
    else {
        MLAlertView *alert = [[MLAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device is not configured to send emails."
                                                         button:@"OK"];
        [alert show];
    }
}

/** 
 Updates medication basket HTML string
 */
- (void) updateInteractionBasketView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    // TODO: Optimize: pre-load the following files
    
    // Load style sheet from file
    NSString *interactionsCssPath = [[NSBundle mainBundle] pathForResource:@"interactions_css" ofType:@"css"];
    NSString *interactionsCss = [NSString stringWithContentsOfFile:interactionsCssPath encoding:NSUTF8StringEncoding error:nil];
    
    // Load JavaScript from file
    NSString *js_Script;
    {
    NSString *jscriptPath = [[NSBundle mainBundle] pathForResource:@"deleterow" ofType:@"js"];
    NSString *jscriptStr = [NSString stringWithContentsOfFile:jscriptPath encoding:NSUTF8StringEncoding error:nil];
    js_Script = [NSString stringWithFormat:@"<script type=\"text/javascript\">%@</script>", jscriptStr];
    }
    
    // Generate main interaction table
    NSString *html = [NSString stringWithFormat:@"<html><head><meta charset=\"utf-8\" />"];
    html = [html stringByAppendingFormat:@"%@<style type=\"text/css\">%@</style></head><body><div id=\"interactions\">%@<br><br>%@<br>%@</div></body></html>",
            js_Script,
            interactionsCss,
            [self medBasketHtml],
            [self interactionsHtml],
            [self footNoteHtml]];
    
    self.htmlStr = [NSString stringWithFormat:@"<head><style>%@</style></head>%@", interactionsCss, html];
    
//#ifdef DEBUG
//    NSUInteger length = [htmlStr length];
//    
//    NSLog(@"%s line %d, htmlStr head :\n\n%@", __FUNCTION__, __LINE__,
//          [htmlStr substringToIndex:MIN(500,length)]);
//    
//    NSLog(@"%s line %d, htmlStr tail :\n\n%@", __FUNCTION__, __LINE__,
//          [htmlStr substringFromIndex:length - MIN(200,length)]);
//#endif

    [self updateWebView];
}

/** 
 Updates main webview in second viewcontroller
 */
- (void) updateWebView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
    //NSLog(@"%s htmlStr:\n\n%@", __FUNCTION__, [htmlStr substringToIndex:MIN(500,[htmlStr length])]);
#endif
    
    if ([self.htmlStr isEqualToString:@"Interactions"])
        [self updateInteractionBasketView];

    NSURL *mainBundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Loads HTML directly into webview
    [self.webView loadHTMLString:self.htmlStr
                         baseURL:mainBundleURL];
    /*
     [self.webView stopLoading];
     [self.webView reload];
     */
}

#pragma mark - medication basket methods

/** 
 Creates interaction basket html string
 */
- (NSString *) medBasketHtml
{
    // basket_html_str + delete_all_button_str + "<br><br>" + top_note_html_str
    int medCnt = 0;
    NSString *medBasketStr = [NSString stringWithFormat:
                              @"<div id=\"Medikamentenkorb\"><fieldset><legend>%@</legend></fieldset></div>"
                              @"<table id=\"InterTable\" width=\"100%%25\">",
                              NSLocalizedString(@"Drugs Basket", nil)];
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([medBasket count]>0) {
        // First sort them alphabetically
        NSArray *sortedNames = [[medBasket allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Loop through all meds
        for (NSString *name in sortedNames) {
            MLMedication *med = [medBasket valueForKey:name];
            NSArray *m_code = [[med atccode] componentsSeparatedByString:@";"];
            NSString *atc_code = @"k.A.";
            NSString *active_ingredient = @"k.A";
            if ([m_code count]>1) {
                atc_code = [m_code objectAtIndex:0];
                active_ingredient = [m_code objectAtIndex:1];
            }
            // Increment med counter
            medCnt++;
            // Update medication basket
            medBasketStr = [medBasketStr stringByAppendingFormat:@"<tr>"
                            @"<td>%d</td>"
                            @"<td>%@</td>"
                            @"<td>%@</td>"
                            @"<td>%@</td>"
                            @"<td align=\"right\"><input type=\"image\" src=\"217-trash.png\" onclick=\"deleteRow('Single','InterTable',this)\" />"
                            @"</tr>", medCnt, name, atc_code, active_ingredient];
        }

        // Add delete all button
        medBasketStr = [medBasketStr stringByAppendingFormat:@"</table>"
                        @"<div id=\"Delete_all\"><input type=\"button\" "
                        @"value=\"%@\" "
                        @"onclick=\"deleteRow('Delete_all','InterTable',this)\" /></div>",
                        NSLocalizedString(@"Delete everything", nil)];
    }
    else {
        medBasketStr = [NSString stringWithFormat:@"<div>%@<br><br></div>",
                        NSLocalizedString(@"Your medicine basket is empty", nil)];
    }
    
    return medBasketStr;
}

- (NSString *) topNoteHtml
{
    NSString *topNote = @"";
    
    if ([medBasket count]>1) {
        // Add note to indicate that there are no interactions
        topNote = [NSString stringWithFormat:
                   @"<fieldset><legend>%@</legend></fieldset>"
                   @"<p>%@</p>",
                   NSLocalizedString(@"Known interactions", nil),
                   NSLocalizedString(@"If no interactions are displayed, no interactions known", nil)];
    }
    
    return topNote;
}

/**
 Creates html displaying interactions between drugs
 */
- (NSString *) interactionsHtml
{  
    NSMutableString *interactionStr = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *sectionIds = [[NSMutableArray alloc] initWithObjects:@"Medikamentenkorb", nil];
    NSMutableArray *sectionTitles = nil;
    
    if ([medBasket count]>0)
        sectionTitles = [[NSMutableArray alloc] initWithObjects:NSLocalizedString(@"Drugs Basket", nil), nil];
    
    // Check if there are meds in the "Medikamentenkorb"
    if ([medBasket count]>1) {
        [interactionStr appendString:[NSString stringWithFormat:
                                      @"<fieldset><legend>%@</legend></fieldset>",
                                      NSLocalizedString(@"Known interactions", nil)]];

        // First sort them alphabetically
        NSArray *sortedNames = [[medBasket allKeys] sortedArrayUsingSelector: @selector(compare:)];
        // Big loop
        for (NSString *name1 in sortedNames) {
            for (NSString *name2 in sortedNames) {
                if (![name1 isEqualToString:name2]) {
                    // Extract meds by names from interaction basket
                    MLMedication *med1 = [medBasket valueForKey:name1];
                    MLMedication *med2 = [medBasket valueForKey:name2];
                    // Get ATC codes from interaction db
                    NSArray *m_code1 = [[med1 atccode] componentsSeparatedByString:@";"];
                    NSArray *m_code2 = [[med2 atccode] componentsSeparatedByString:@";"];
                    NSArray *atc1 = nil;
                    NSArray *atc2 = nil;
                    if ([m_code1 count]>1)
                        atc1 = [[m_code1 objectAtIndex:0] componentsSeparatedByString:@","];
                    if ([m_code2 count]>1)
                        atc2 = [[m_code2 objectAtIndex:0] componentsSeparatedByString:@","];
                    
                    NSString *atc_code1 = @"";
                    NSString *atc_code2 = @"";
                    if (atc1!=nil && [atc1 count]>0) {
                        for (atc_code1 in atc1) {
                            if (atc2!=nil && [atc2 count]>0) {
                                for (atc_code2 in atc2) {
                                    NSString *html = [self.dbAdapter getInteractionHtmlBetween:atc_code1 and:atc_code2];
                                    if (html!=nil) {
                                        // Replace all occurrences of atc codes by med names apart from the FIRST one!
                                        NSRange range1 = [html rangeOfString:atc_code1 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range1 withString:name1];
                                        NSRange range2 = [html rangeOfString:atc_code2 options:NSBackwardsSearch];
                                        html = [html stringByReplacingCharactersInRange:range2 withString:name2];
                                        // Concatenate strings
                                        [interactionStr appendString:html];
                                        // Add to title and anchor lists
                                        [sectionTitles addObject:[NSString stringWithFormat:@"%@ \u2192 %@", name1, name2]];
                                        [sectionIds addObject:[NSString stringWithFormat:@"%@-%@", atc_code1, atc_code2]];
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        if ([sectionTitles count]<2) {
            // TODO: proper localization, not based on the database language
            if ([[MLConstants databaseLanguage] isEqualToString:@"de"])
                [interactionStr appendString:@"<p class=\"paragraph0\">Zur Zeit sind keine Interaktionen zwischen diesen Medikamenten in der EPha.ch-Datenbank vorhanden. Weitere Informationen finden Sie in der Fachinformation.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Interaktion melden\" onclick=\"deleteRow('Notify_interaction','InterTable',this)\" /></div><br>"];
            else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"])
                [interactionStr appendString:@"<p class=\"paragraph0\">Il n’y a aucune information dans la banque de données EPha.ch à propos d’une interaction entre les médicaments sélectionnés. Veuillez consulter les informations professionelles.</p><div id=\"Delete_all\"><input type=\"button\" value=\"Signaler une interaction\" onclick=\"deleteRow('Notify_interaction','InterTable',this)\" /></div><br>"];
        }
        else if ([sectionTitles count]>2) {
            [interactionStr appendString:@"<br>"];
        }
    }
    
    if ([medBasket count]>0) {
        // TODO: proper localization, not based on the database language
        [sectionIds addObject:@"Farblegende"];
        if ([[MLConstants databaseLanguage] isEqualToString:@"de"])
            [sectionTitles addObject:@"Farblegende"];
        else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"])
            [sectionTitles addObject:@"Légende des couleurs"];
    }
    
    if (titleViewController!=nil) {
        [titleViewController setSectionTitles:[NSArray arrayWithArray:sectionTitles]
                                       andIds:[NSArray arrayWithArray:sectionIds]];
    }
    
    return interactionStr;
}

- (NSString *) footNoteHtml
{
    /*
     Risikoklassen
     -------------
     A: Keine Massnahmen notwendig (grün)
     B: Vorsichtsmassnahmen empfohlen (gelb)
     C: Regelmässige Überwachung (orange)
     D: Kombination vermeiden (pinky)
     X: Kontraindiziert (hellrot)
     0: Keine Angaben (grau)
     */
    if ([medBasket count]>0) {
        // TODO: proper localization, not based on the database language
        if ([[MLConstants databaseLanguage] isEqualToString:@"de"]) {
            NSString *legend = {
                @"<fieldset><legend>Fussnoten</legend></fieldset>"
                @"<p class=\"footnote\">1. Farblegende: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:#ffffff;\" cellpadding=\"3px\" width=\"100%25\">"
                @"  <tr bgcolor=\"#caff70\"><td align=\"center\">A</td><td>Keine Massnahmen notwendig</td></tr>"
                @"  <tr bgcolor=\"#ffec8b\"><td align=\"center\">B</td><td>Vorsichtsmassnahmen empfohlen</td></tr>"
                @"  <tr bgcolor=\"#ffb90f\"><td align=\"center\">C</td><td>Regelmässige Überwachung</td></tr>"
                @"  <tr bgcolor=\"#ff82ab\"><td align=\"center\">D</td><td>Kombination vermeiden</td></tr>"
                @"  <tr bgcolor=\"#ff6a6a\"><td align=\"center\">X</td><td>Kontraindiziert</td></tr>"
                @"</table>"
                @"<p class=\"footnote\">2. Datenquelle: Public Domain Daten von EPha.ch.</p>"
                @"<p class=\"footnote\">3. Unterstützt durch:  IBSA Institut Biochimique SA.</p>"
            };
            return legend;
        }
        else if ([[MLConstants databaseLanguage] isEqualToString:@"fr"]) {
            NSString *legend = {
                @"<fieldset><legend>Notes</legend></fieldset>"
                @"<p class=\"footnote\">1. Légende des couleurs: </p>"
                @"<table id=\"Farblegende\" style=\"background-color:#ffffff;\" cellpadding=\"3px\" width=\"100%25\">"
                @"  <tr bgcolor=\"#caff70\"><td align=\"center\">A</td><td>Aucune mesure nécessaire</td></tr>"
                @"  <tr bgcolor=\"#ffec8b\"><td align=\"center\">B</td><td>Mesures de précaution sont recommandées</td></tr>"
                @"  <tr bgcolor=\"#ffb90f\"><td align=\"center\">C</td><td>Doit être régulièrement surveillée</td></tr>"
                @"  <tr bgcolor=\"#ff82ab\"><td align=\"center\">D</td><td>Eviter la combinaison</td></tr>"
                @"  <tr bgcolor=\"#ff6a6a\"><td align=\"center\">X</td><td>Contre-indiquée</td></tr>"
                @"</table>"
                @"<p class=\"footnote\">2. Source des données : données du domaine publique de EPha.ch.</p>"
                @"<p class=\"footnote\">3. Soutenu par : IBSA Institut Biochimique SA.</p>"
            };
            return legend;
        }
    }
    
    return @"";
}

#pragma mark - UISearchBarDelegate methods

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
#ifdef DEBUG
    NSLog(@"%s line %d, searchText: %@", __FUNCTION__, __LINE__, searchText);
#endif

    mCurrentSearch = searchText;
    
    if ([searchText length] > 2) {
        mTotalHighlights = (int)[self.webView highlightAllOccurencesOfString:searchText];
#ifdef DEBUG
        NSLog(@"%s line %d, mTotalHighlights: %d, mCurrentHightlight: %d", __FUNCTION__, __LINE__, mTotalHighlights, mCurrentHightlight);
#endif
        mCurrentHightlight = 0;
        if (mTotalHighlights>1) {
            [self.webView nextHighlight:mTotalHighlights-1];
            [self showFindPanel:FIND_PANEL_VISIBLE];
            [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
        }
        else {
            [self showFindPanel:FIND_PANEL_INVISIBLE];
        }
    }
    else {
        [self.webView removeAllHighlights];
        mTotalHighlights = 0;
        [self showFindPanel:FIND_PANEL_INVISIBLE];
    }
}

- (void) showFindPanel:(FindPanelVisibility)visible
{
#ifdef DEBUG
    NSLog(@"%s line %d, visible: %ld, was %ld", __FUNCTION__, __LINE__,
          (long)visible, (long)mIsFindPanelVisible);
#endif

    if ((visible == mIsFindPanelVisible) ||
        (visible == FIND_PANEL_UNDEFINED)) {
        return;
    }

    mIsFindPanelVisible = visible;
    
    CGRect newFrame = self.findPanel.frame;
    
    if (visible == FIND_PANEL_VISIBLE) {
        // newFrame.origin.x = x - 200;
        newFrame.origin.y = mFramePosA;
    }
    else {
        // newFrame.origin.x = x + 200;
        newFrame.origin.y = mFramePosB;
    }
    
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.findPanel.frame = newFrame;
                     }
                     completion:^(BOOL finished){
                         if (visible == FIND_PANEL_VISIBLE) {
                             [self.findPanel setHidden:NO];
                         }
                         else {
                             [self.findPanel setHidden:YES];
                         }
                     }];

    if (visible == FIND_PANEL_VISIBLE) {
        [self.findPanel setHidden:NO];
        [self.findCounter setHidden:NO];
    }
    else {
        [self.findCounter setHidden:YES];
    }
}

#pragma mark - UIWebViewDelegate methods

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    // Check this out!
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        int fontSize = 80;
        NSString *jsString = [[NSString alloc] initWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%d%%'", fontSize];
        [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    }

    if ([htmlAnchor length] > 0) {
#ifdef DEBUG
        NSLog(@"%s, htmlAnchor: %@", __FUNCTION__, htmlAnchor);
#endif
        // NSString *res =
        [self.webView stringByEvaluatingJavaScriptFromString:htmlAnchor];
    }
    
    // int height =
    [[self.webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight;"] intValue];
    
    self.webView.scalesPageToFit = NO;  // YES
    self.webView.scrollView.zoomScale = 3.0;

#ifdef DEBUG
    NSLog(@"%s line %d, keyword:<%@>", __FUNCTION__, __LINE__, keyword);
#endif

    if ([keyword length] > 0) {
        mTotalHighlights = (int)[self.webView highlightAllOccurencesOfString:keyword];

        [self showFindPanel:FIND_PANEL_VISIBLE];
        
#ifdef DEBUG
        NSLog(@"%s line %d, mTotalHighlights: %d", __FUNCTION__, __LINE__, mTotalHighlights);
#endif
        [self.findCounter setText:[NSString stringWithFormat:@"%d/%d", mCurrentHightlight+1, mTotalHighlights]];
        // TBC: as a result highlightAllOccurencesOfString is called again ?
    }
    else {
        // Hide find panel (webview is the superview of the panel)
        [self showFindPanel:FIND_PANEL_INVISIBLE];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error
{
    UIViewController *presentingController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [presentingController dismissViewControllerAnimated:YES completion:nil];
    
    NSString* message = nil;
    switch (result) {
        case MFMailComposeResultCancelled:
            message = @"No mail sent at user request.";
            break;
        case MFMailComposeResultSaved:
            message = @"Draft saved";
            break;
        case MFMailComposeResultSent:
            message = @"Mail sent";
            break;
        case MFMailComposeResultFailed:
            message = @"Error";
    }
    
#ifdef DEBUG
    // Do something with the message
    NSLog(@"%s, error: %@, message: %@", __FUNCTION__, error, message);
#endif
}

// See `darkModeChanged` in AmiKo osx
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
#ifdef DEBUG
    NSLog(@"%s, previous style, %ld, current style:%ld", __FUNCTION__,
          (long)previousTraitCollection.userInterfaceStyle,
          [UITraitCollection currentTraitCollection].userInterfaceStyle);
#endif
    
    // Post message to switchToAips
    UIViewController *nc_rear = self.revealViewController.rearViewController;
    MLViewController *vc_rear = [nc_rear.childViewControllers firstObject];
    NSArray *toolbarItems = [vc_rear.myToolBar items];
    NSLog(@"%@", toolbarItems);
    //[vc_rear switchToAipsViewFromFulltext: messageDictionary];
}

@end
