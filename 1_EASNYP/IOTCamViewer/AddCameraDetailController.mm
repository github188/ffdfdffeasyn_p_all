//
//  AddCameraDetailController.m
//  IOTCamViewer
//
//  Created by tutk on 12/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AddCameraDetailController.h"
#import "AppDelegate.h"
#import "QRCodeReader.h"
#import "StartViewController.h"

@implementation AddCameraDetailController

@synthesize fieldLabels;
@synthesize textFieldName, textFieldUID, textFieldPassword;
@synthesize uid;
@synthesize ssid;
@synthesize name;
@synthesize tableView;
@synthesize delegate;

- (void)setNameFieldBecomeFirstResponder:(BOOL)value {
    
    isNameFieldBecomeisFirstResponder = value;
}

- (void)setPasswordFieldBecomeFirstResponder:(BOOL)value {
    
    isPasswordFieldBecomeFirstResponder = value;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<AddCameraDelegate>)delegate_ {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        [self setDelegate:delegate_];
    }
    
    return self;
}

- (void)showListFullMesg
{
    NSString *msg = NSLocalizedString(@"List are full, remove a device and try again", @"");
    NSString *dismiss = NSLocalizedString(@"Dismiss", @"");
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:dismiss otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (IBAction)scanQRCode:(id)sender {
    if ([camera_list count] >= MAX_CAMERA_LIMIT) {
        
        [self showListFullMesg];
        return;
    }
    
    ZXingWidgetController *controller = [[ZXingWidgetController alloc] initWithDelegate:self showCancel:YES OneDMode:NO];
    QRCodeReader* qrcodeReader = [[QRCodeReader alloc] init];
    
    NSSet *readers = [[NSSet alloc] initWithObjects:qrcodeReader, nil];
    controller.readers = readers;
    [readers release];
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    controller.soundToPlay = [NSURL fileURLWithPath:[mainBundle pathForResource:@"beep-beep" ofType:@"aiff"] isDirectory:NO];
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    [qrcodeReader release];
}

- (IBAction)scanLanSearch:(id)sender {
    LANSearchController *controller = [[LANSearchController alloc] init];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (IBAction)syncOnCloud:(id)sender {
    
    if (isFromDOC) {
        isSyncOnCloud = !isSyncOnCloud;
        
        if (isSyncOnCloud){
            [syncButton setBackgroundImage:[UIImage imageNamed:@"add_sync_clicked"] forState:UIControlStateNormal];
        } else {
            [syncButton setBackgroundImage:[UIImage imageNamed:@"add_sync"] forState:UIControlStateNormal];
        }
    } else {
        isAddToCloud =!isAddToCloud;
        
        if (isAddToCloud){
            [syncButton setBackgroundImage:[UIImage imageNamed:@"add_sync_clicked"] forState:UIControlStateNormal];
            
            
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            if ([userDefaults objectForKey:@"cloudUserPassword"]) {
                
                isLogin = YES;
                
                NSString *msg = NSLocalizedString(@"Do you want to sync the device with your account?", @"");
                NSString *no = NSLocalizedString(@"NO", @"");
                NSString *yes = NSLocalizedString(@"YES", @"");
                NSString *caution = NSLocalizedString(@"Caution!", @"");
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:caution message:msg delegate:self cancelButtonTitle:no otherButtonTitles:yes, nil];
                [alert show];
                [alert release];
            } else {
                
                isLogin = NO;
                
                NSString *msg = NSLocalizedString(@"Do you want to login your account?", @"");
                NSString *cancelMsg = NSLocalizedString(@"Cancel", @"");
                NSString *Login = NSLocalizedString(@"Login", @"");
                NSString *caution = NSLocalizedString(@"Caution!", @"");
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:caution message:msg delegate:self cancelButtonTitle:cancelMsg otherButtonTitles:Login, nil];
                [alert show];
                [alert release];
            }
            
        } else {
            [syncButton setBackgroundImage:[UIImage imageNamed:@"add_sync"] forState:UIControlStateNormal];
        }
    }
    
}

- (IBAction)cancel:(id)sender {
    
    //[self.navigationController popViewControllerAnimated:YES];
    [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:1] animated:YES];
}

- (IBAction)save:(id)sender {
    
    NSString *name_ = textFieldName.text;
    NSString *uid_ = textFieldUID.text;
    NSString *password = textFieldPassword.text;
    
    name_ = [name_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    uid_ = [uid_ stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSLog(@"name:'%s', uid:'%s'(%d), password:'%s'",[name_ UTF8String], [uid_ UTF8String], [uid_ length], [password UTF8String]);
    
    if (uid_ == nil || [uid_ length] != 20) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"") message:NSLocalizedString(@"Camera UID length must be 20 characters", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }    
    else if (name_ == nil || [name_ length] == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"") message:NSLocalizedString(@"Camera Name can not be empty", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else if (password == nil || [password length] == 0) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"") message:NSLocalizedString(@"Camera Password can not be empty", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    else if ([name_ length] > 0 && [uid_ length] == 20 && [password length] > 0) {
        
        for (Camera *cam in camera_list) {
            
            if ([cam.uid isEqualToString:uid_]) {
                
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"This device is already exists", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
                
                [alert show];
                [alert release];
                
                return;
            }
        }
        
        
        
#if defined(IDHDCONTROL)
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        NSDictionary *dic=@{@"id":[NSString stringWithFormat:@"%ld",(long)[AccountInfo getUserId]],@"uuid":[MyCamera boxUUID:uid_ widthPwd:password withName:name_]};
        HttpTool *httpTool=[HttpTool shareInstance];
        [httpTool JsonGetRequst:@"/index.php?ctrl=app&act=saveUuid" parameters:dic success:^(id responseObject) {
            [MBProgressHUD hideAllHUDsForView: self.view animated:YES];
            NSInteger code=[responseObject[@"code"]integerValue];
            NSString *msg=responseObject[@"msg"];
            if(code==1){
                [self alertInfo:msg withTitle:NSLocalizedStringFromTable(@"提示", @"login", nil)];
            }
            else{
                
                [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:0] animated:YES];
                
                [self.delegate camera:uid_ didAddwithName:name_ password:password syncOnCloud:isSyncOnCloud addToCloud:isAddToCloud addFromCloud:isFromDOC];
            }
        } failure:^(NSError *error) {
            [MBProgressHUD hideAllHUDsForView: self.view animated:YES];
            [self alertInfo:error.localizedDescription withTitle:NSLocalizedStringFromTable(@"提示", @"login", nil)];
        }];
#else
        [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:0] animated:YES];
        
        [self.delegate camera:uid_ didAddwithName:name_ password:password syncOnCloud:isSyncOnCloud addToCloud:isAddToCloud addFromCloud:isFromDOC];
#endif
        
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", @"") message:NSLocalizedString(@"The name, uid and password field can not be empty", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}
-(void)alertInfo:(NSString *)message withTitle:(NSString *)title{
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    [alert show];
    [alert release];
}
- (IBAction)textFieldDone:(id)sender 
{    
    [sender resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == textFieldName) {
        [textFieldUID becomeFirstResponder];
    }
    
    if (textField == textFieldUID) {
        [textFieldPassword becomeFirstResponder];
    }
    
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - View lifecycle

- (void)dealloc {
    
    self.delegate = nil;
    
    [tableView release];
    [fieldLabels release];
    [textFieldName release];
    [textFieldUID release];
    [textFieldPassword release];
    [_qrBtn release];
    [_lansBtn release];
    [_qrLbl release];
    [lanSearch release];
    [super dealloc];
}

- (void)viewDidLoad {
    
    isSyncOnCloud = NO;
    isAddToCloud = NO;
    
    lanSearch.text = NSLocalizedString(@"LAN Search", @"");
    [add setTitle:NSLocalizedString(@"Add", @"") forState:UIControlStateNormal];
    [cancel setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([[userDefaults objectForKey:@"wifiSetting"] integerValue] == 0){
        noWiFiSetting.hidden = NO;
    }
    
    if (isFromDOC) {
        syncLabel.text = NSLocalizedString(@"Sync with your cloud account", @"");
        noWiFiSetting.hidden = YES;
        
    } else {
        syncLabel.text = NSLocalizedString(@"Add device to your cloud account", @"");
    }
    if(self.isFromAutoWifi){
        noWiFiSetting.hidden=YES;
    }
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    self.qrBtn.hidden=self.isFromAutoWifi;
    self.qrLbl.hidden=self.isFromAutoWifi;
    self.qrLbl.text=NSLocalizedString(@"QRCode", @"");
    self.lansBtn.hidden=self.isFromAutoWifi;
    lanSearch.hidden=self.isFromAutoWifi;
    if (screenBounds.size.height == 480) {
        checkView.y -= 84;
        syncButton.y -= 60;
        syncLabel.y -= 60;
        if(self.isFromAutoWifi){
            self.tableView.height += 122+80;
            self.tableView.y=0;
            [self.view bringSubviewToFront:self.tableView];
        }
        else{
            self.tableView.height += 80;
            self.tableView.y -= 20;
        }
    }
    else{
        if(self.isFromAutoWifi){
            self.tableView.height +=122;
            self.tableView.y = 0;
            [self.view bringSubviewToFront:self.tableView];
        }
    }
    
    NSArray *array = [[NSArray alloc] initWithObjects:NSLocalizedString(@"UID", @""), NSLocalizedString(@"Password", @""), NSLocalizedString(@"Name", @""), nil];
    self.fieldLabels = array;
    [array release];
    
    self.tableView.opaque = NO;
    self.tableView.sectionIndexColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView  = nil;
    self.tableView.separatorColor = [UIColor whiteColor];
    
    self.navigationItem.title = NSLocalizedString(@"Add Camera", @"");
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                     initWithTitle:NSLocalizedString(@"", @"")
                                     style:UIBarButtonItemStylePlain
                                     target:self
                                     action:nil];
    self.navigationItem.leftBarButtonItem = cancelButton;
    [cancelButton release];
	
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc]
                                   initWithTitle:NSLocalizedString(@"", @"")
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:nil];
    self.navigationItem.rightBarButtonItem = saveButton;
    [saveButton release];
    
	AppDelegate* currentAppDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
	if( currentAppDelegate.mOpenUrlCmdStore.cmd == emAddDeviceByUID ) {
		self.uid = [NSString stringWithFormat:@"%s", currentAppDelegate.mOpenUrlCmdStore.uid ];
		
		[currentAppDelegate urlCommandDone];
	}
    
    SSID.text = ssid;
    
#if defined(SVIPCLOUD)
    textFieldName.textColor=HexRGB(0x3d3c3c);
    textFieldUID.textColor=HexRGB(0x3d3c3c);
    textFieldPassword.textColor=HexRGB(0x3d3c3c);
    [add setTitleColor:HexRGB(0x3d3c3c) forState:UIControlStateNormal];
    [cancel setTitleColor:HexRGB(0x3d3c3c) forState:UIControlStateNormal];
    
    lanSearch.textColor=HexRGB(0x3d3c3c);
    _qrLbl.textColor=HexRGB(0x3d3c3c);
    SSID.textColor=HexRGB(0x3d3c3c);
    
#endif
    
    
    [super viewDidLoad];
}

- (void)viewDidUnload { 
    
    self.tableView = nil;    
    self.fieldLabels = nil;
    self.textFieldName = nil;
    self.textFieldUID = nil;
    self.textFieldPassword = nil;
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}
-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    /****上方坐标设置***/
    CGFloat marginW=100.f;
    CGFloat marginLRW=(self.view.frame.size.width-self.qrBtn.frame.size.width-self.lansBtn.frame.size.width-marginW)/2;
    self.qrBtn.frame=CGRectMake(marginLRW, self.qrBtn.frame.origin.y, self.qrBtn.frame.size.width, self.qrBtn.frame.size.height);
    self.qrLbl.frame=CGRectMake(marginLRW+(self.qrBtn.frame.size.width/2-self.qrLbl.frame.size.width/2), self.qrLbl.frame.origin.y, self.qrLbl.frame.size.width, self.qrLbl.frame.size.height);
    
    self.lansBtn.frame=CGRectMake(self.qrBtn.frame.size.width+self.qrBtn.frame.origin.x+marginW, self.lansBtn.frame.origin.y, self.lansBtn.frame.size.width, self.lansBtn.frame.size.height);
    lanSearch.frame=CGRectMake(self.lansBtn.frame.origin.x+(self.lansBtn.frame.size.width/2-lanSearch.frame.size.width/2), lanSearch.frame.origin.y, lanSearch.frame.size.width, lanSearch.frame.size.height);
    
    self.tableView.frame=CGRectMake(0, noWiFiSetting.frame.size.height, self.view.frame.size.width, self.view.frame.size.height-noWiFiSetting.frame.size.height-checkView.frame.size.height);
    checkView.frame=CGRectMake(0, self.view.frame.size.height-checkView.frame.size.height, self.view.frame.size.width, checkView.frame.size.height);
    
    marginW=50;
    marginLRW=(self.view.frame.size.width-add.frame.size.width-cancel.frame.size.width-marginW)/2;
    add.frame=CGRectMake(marginLRW, add.frame.origin.y, add.frame.size.width, add.frame.size.height);
    cancel.frame=CGRectMake(add.frame.origin.x+add.frame.size.width+marginW, cancel.frame.origin.y, cancel.frame.size.width, cancel.frame.size.height);
}

- (void)viewDidAppear:(BOOL)animated {
    
    if (isNameFieldBecomeisFirstResponder) {
        [self.textFieldName becomeFirstResponder];
    }
    
    if (isPasswordFieldBecomeFirstResponder) {
        [self.textFieldPassword becomeFirstResponder];
    }
    
    [super viewDidAppear:animated];
}

#pragma mark - Table DataSource Methods
- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section {
    
    return NUMBER_OF_EDITABLE_ROWS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSUInteger row = [indexPath row];

    static NSString *AddCameraCellIdentifier = @"AddCameraCellIdentifier";
	
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:
                             AddCameraCellIdentifier];
    if (cell == nil) {
		
        cell = [[[UITableViewCell alloc]
				 initWithStyle:UITableViewCellStyleDefault
				 reuseIdentifier:AddCameraCellIdentifier] autorelease];
        
        cell.textLabel.text = [fieldLabels objectAtIndex:row];
        cell.textLabel.textColor = [UIColor whiteColor];
#if defined(SVIPCLOUD)
        cell.textLabel.textColor=HexRGB(0x3d3c3c);
#endif
        cell.opaque = NO;
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = nil;
        cell.textLabel.font=[UIFont systemFontOfSize:13.0f];
        
                
        if (row == 0) {
            
            textFieldUID = [[UITextField alloc] initWithFrame: CGRectMake(115, 11, 180, 25)];
            textFieldUID.placeholder = NSLocalizedString(@"Camera UID", @"");
            textFieldUID.clearsOnBeginEditing = NO;
            textFieldUID.font=[UIFont systemFontOfSize:13.0f];
            textFieldUID.clearButtonMode = UITextFieldViewModeWhileEditing;
            [textFieldUID setDelegate:self];
            [textFieldUID addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
            textFieldUID.textColor = [UIColor whiteColor];
            [cell.contentView addSubview:textFieldUID];
            
        } else if (row == 1) {
            
            textFieldPassword = [[UITextField alloc] initWithFrame: CGRectMake(115, 11, 180, 25)];
            textFieldPassword.placeholder = NSLocalizedString(@"Camera Password", @"");
            textFieldPassword.clearsOnBeginEditing = NO;
            textFieldPassword.font=[UIFont systemFontOfSize:13.0f];
            textFieldPassword.clearButtonMode = UITextFieldViewModeWhileEditing;
            textFieldPassword.secureTextEntry = YES;
            [textFieldPassword setDelegate:self];
            [textFieldPassword addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
            textFieldPassword.textColor = [UIColor whiteColor];
            self.textFieldPassword.text=@"admin";
            [cell.contentView addSubview:textFieldPassword];
            
        } else if (row == 2) {
            
            textFieldName = [[UITextField alloc] initWithFrame: CGRectMake(115, 11, 180, 25)];
            textFieldName.placeholder = NSLocalizedString(@"Camera Name", @"");
            textFieldName.clearsOnBeginEditing = NO;
            textFieldName.font=[UIFont systemFontOfSize:13.0f];
            textFieldName.clearButtonMode = UITextFieldViewModeWhileEditing;
            [textFieldName setDelegate:self];
            [textFieldName addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
            textFieldName.textColor = [UIColor whiteColor];
            [cell.contentView addSubview:textFieldName];
            
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
     
    switch (row) {
            
        case 0:
        {
            textFieldUID.text = self.uid;
            textFieldUID.clearButtonMode = UITextFieldViewModeWhileEditing;
        }
        break;
            
        case 1:
        {
            textFieldPassword.clearButtonMode = UITextFieldViewModeWhileEditing;
        }
        break;
            
        case 2:
        {
            if (self.name.length == 0) {
                self.textFieldName.text = NSLocalizedString(@"Camera", @"");
            } else {
                self.textFieldName.text = self.name;
            }
            
            textFieldName.clearButtonMode = UITextFieldViewModeWhileEditing;
        }
        break;
        default:
            break;
    }
        
    return cell;
}

#pragma mark - Table Delegate Methods
- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return nil;
}

#pragma mark - Text Field Delegate Methods
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{    
    if (textField.tag == 99) {
                
        NSUInteger len = [textField.text length] + [string length] - range.length;  
           
        if (len <= 20)
            textField.text = [textField.text stringByReplacingCharactersInRange:range withString:[string uppercaseString]];

        return NO;
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (screenBounds.size.height == 480) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y - 80,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
        
        [UIView commitAnimations];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    if (screenBounds.size.height == 480) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelegate:self];
        
        [UIView setAnimationBeginsFromCurrentState:YES];
        
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y + 80,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
        
        [UIView commitAnimations];
    }
}

#pragma mark - UIAlertViewDelegate implementation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && isLogin) {
        isSyncOnCloud = YES;
    } else if (buttonIndex == 1 && !isLogin) {
        StartViewController *controller = [[StartViewController alloc] initWithNibName:@"StartView" bundle:nil];
        controller->isFromDOC = YES;
        [self.navigationController pushViewController:controller animated:YES];
    }
}


#pragma mark - LanSearchDelegate Methods
- (void)didSelectUID:(NSString *)selectedUid {
    textFieldUID.text = selectedUid;
}

#pragma mark - Zxing Delegate Methods
- (void)zxingController:(ZXingWidgetController *)controller_
          didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    textFieldUID.text = result;
}

- (void)zxingControllerDidCancel:(ZXingWidgetController*)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory 
{    
    return [[[NSFileManager defaultManager] 
             URLsForDirectory:NSDocumentDirectory 
             inDomains:NSUserDomainMask] lastObject];
}
@end
