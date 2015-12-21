//
//  MyCamera.m
//  IOTCamViewer
//
//  Created by Cloud Hsiao on 12/7/2.
//  Copyright (c) 2012年 TUTK. All rights reserved.
//

#import "MyCamera.h"
#import <IOTCamera/AVIOCTRLDEFs.h>
#import <IOTCamera/AVFrameInfo.h>

BOOL g_bDiagnostic = FALSE;

@interface MyCamera()

@property(readwrite) NSInteger remoteNotifications;

@end

@implementation MyCamera
@synthesize delegate2;
@synthesize lastChannel;
@synthesize remoteNotifications;
@synthesize viewAcc, viewPwd;
@synthesize bIsSupportTimeZone;
@synthesize bIsSyncOnCloud;
@synthesize bisAddFromCloud;
@synthesize nGMTDiff;
@synthesize strTimeZone;
@synthesize isSupportDropbox;
@synthesize isLinkDropbox;

#pragma mark - Public Methods

- (NSArray *)getSupportedStreams 
{
    return [arrayStreamChannel count] == 0 ? nil : [[[NSArray alloc] initWithArray:arrayStreamChannel] autorelease];
}

- (BOOL)getAudioInSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 1) == 0;
}

- (BOOL)getAudioOutSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 2) == 0;
}

- (BOOL)getPanTiltSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 4) == 0;    
}

- (BOOL)getEventListSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 8) == 0;   
}

- (BOOL)getPlaybackSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 16) == 0;   
}

- (BOOL)getWiFiSettingSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 32) == 0;
}

- (BOOL)getMotionDetectionSettingSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 64) == 0;  
}

- (BOOL)getRecordSettingSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 128) == 0;   
}

- (BOOL)getFormatSDCardSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 256) == 0;
}

- (BOOL)getVideoFlipSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 512) == 0;  
}

- (BOOL)getEnvironmentModeSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 1024) == 0;
}

- (BOOL)getMultiStreamSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 2048) == 0;
}

- (NSInteger)getAudioOutFormatOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 4096) == 0 ? MEDIA_CODEC_AUDIO_SPEEX : MEDIA_CODEC_AUDIO_ADPCM;  
}

- (BOOL)getVideoQualitySettingSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 8192) == 0;
}

- (BOOL)getDeviceInfoSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & 16384) == 0;
}

- (BOOL)getTimeZoneSupportOfChannel:(NSInteger)channel
{
    return ([self getServiceTypeOfChannel:channel] & (0x01<<15)) == 0;
}
+(NSString *)boxUUID:(MyCamera *)camera{
    //uid/密码/画质等级-摄像机名称
    return [NSString stringWithFormat:@"%@/%@/%d-%@",camera.uid,camera.viewPwd,1,camera.name];
}
+(NSString *)boxUUID:(NSString *)uid widthPwd:(NSString *)viewPwd withName:(NSString *)name{
    return [NSString stringWithFormat:@"%@/%@/%d-%@",uid,viewPwd,1,name];
}
+(NSArray *)unBoxUUID:(NSString *)strs{
    NSArray *arr=[strs componentsSeparatedByString:@"/"];
    NSString *uid=[arr objectAtIndex:0];
    if([arr count]==1){
        return [NSArray arrayWithObjects:uid,@"admin",@"1",@"camera",nil];
    }
    
    NSString *pwd=[arr objectAtIndex:1];
    NSString *other=[arr objectAtIndex:2];
    
    NSArray *otherArr=[other componentsSeparatedByString:@"-"];
    NSString *q=[otherArr objectAtIndex:0];
    NSString *name=[otherArr objectAtIndex:1];
    
    return [NSArray arrayWithObjects:uid,pwd,q,name,nil];
}
#pragma mark - 

- (id)init
{
    self = [super init];
    if (self) {
        arrayStreamChannel = [[NSMutableArray alloc] init];
        self.remoteNotifications = 0;
        self.delegate = self;
        
        self.isSupportDropbox = NO;
        self.isLinkDropbox = NO;
    }
    return self;
}

- (id)initWithName:(NSString *)name viewAccount:(NSString *)viewAcc_ viewPassword:(NSString *)viewPwd_
{
    self = [super initWithName:name];
    
    if (self) {
        self.viewAcc = viewAcc_;
        self.viewPwd = viewPwd_;
        self.remoteNotifications = 0;
        self.delegate = self;
        
        self.isSupportDropbox = NO;
        self.isLinkDropbox = NO;
    }
    
    return self;
}

- (void)setSync:(NSInteger)isSync {
    
    if (isSync==0){
        self.bIsSyncOnCloud = NO;
    } else {
        self.bIsSyncOnCloud = YES;
    }
}

- (void)setCloud:(NSInteger)isFromCloud {
    
    if (isFromCloud==0){
        self.bisAddFromCloud = NO;
    } else {
        self.bisAddFromCloud = YES;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didReceiveIOCtrl" object:nil];
    [arrayStreamChannel release];
	[strTimeZone release];
    self.delegate2 = nil;
    [super dealloc];
}

- (void)start:(NSInteger)channel
{
#if defined(IPCAMP) || defined(EasynPTarget)  || defined(BayitCam) || defined(MAJESTICIPCAMP)
    bIsSupportTimeZone = YES;
#else
    bIsSupportTimeZone = NO;
#endif
	nGMTDiff = 8*60;
	strTimeZone = [[NSString alloc] init];
	
    [super start:channel viewAccount:viewAcc viewPassword:viewPwd is_playback:FALSE];
    
#ifdef SUPPORT_DROPBOX
    SMsgAVIoctrlGetDropbox dummy ={0};
    [self sendIOCtrlToChannel:0 Type:IOTYPE_USER_IPCAM_GET_SAVE_DROPBOX_REQ Data:(char *)&dummy DataSize:sizeof(dummy)];
#endif
    
}

- (void)start4EventPlayback:(NSInteger)channel
{
#if defined(IPCAMP) || defined(EasynPTarget)  || defined(BayitCam) ||defined(MAJESTICIPCAMP)
    bIsSupportTimeZone = YES;
#else
    bIsSupportTimeZone = NO;
#endif
	nGMTDiff = 8*60;
	strTimeZone = [[NSString alloc] init];
	
    [super start:channel viewAccount:viewAcc viewPassword:viewPwd is_playback:TRUE];
}

- (void)setRemoteNotification:(NSInteger)type EventTime:(long)time
{
    remoteNotifications++;
    
    NSLog(@"remoteNotifications:%d", remoteNotifications);
    
    if (self.delegate2 != nil && [self.delegate2 respondsToSelector:@selector(camera:_didReceiveRemoteNotification:EventTime:)]) {
        [self.delegate2 camera:self _didReceiveRemoteNotification:type EventTime:time];
    }
}

- (void)clearRemoteNotifications
{
    remoteNotifications = 0;
}

- (NSString*)getOverAllQualityString
{
	NSString* result = nil;
	
	float val = (float)self.nDispFrmPreSec / (float)self.nRecvFrmPreSec;
	
	if( 0.7 <= val ) {
		if( g_bDiagnostic ) {
			result = [NSString stringWithFormat:@"%@ (%d/%d)", NSLocalizedString(@"Good", @""), self.nDispFrmPreSec, self.nRecvFrmPreSec];
		}
		else {
			result = NSLocalizedString(@"Good", @"");
		}
	}
	else if( 0.3 <= val && val < 0.7 ) {
		if( g_bDiagnostic ) {
			result = [NSString stringWithFormat:@"%@ (%d/%d)", NSLocalizedString(@"Normal", @""), self.nDispFrmPreSec, self.nRecvFrmPreSec];
		}
		else {
			result = NSLocalizedString(@"Normal", @"");
		}
	}
	else {
		if( g_bDiagnostic ) {
			result = [NSString stringWithFormat:@"%@ (%d/%d)", NSLocalizedString(@"Bad", @""), self.nDispFrmPreSec, self.nRecvFrmPreSec];
		}
		else {
			result = NSLocalizedString(@"Bad", @"");
		}
	}
	return result;
}

+ (NSString*) getConnModeString:(NSInteger)connMode
{
	NSString* result = nil;
	
	switch(connMode) {
		case CONNECTION_MODE_P2P:
			result = @"P2P";
			break;
		case CONNECTION_MODE_RELAY:
			result = @"Relay";
			break;
		case CONNECTION_MODE_LAN:
			result = @"Lan";
			break;
		default:
			result = @"None";
			break;
	}
	return result;
}

#pragma mark - CameraDelegate Methods
- (void)camera:(Camera *)camera didReceiveRawDataFrame:(const char *)imgData VideoWidth:(NSInteger)width VideoHeight:(NSInteger)height
{
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didReceiveRawDataFrame:VideoWidth:VideoHeight:)]) {
        [self.delegate2 camera:self _didReceiveRawDataFrame:imgData VideoWidth:width VideoHeight:height];
    }
}

- (void)camera:(Camera *)camera didReceiveJPEGDataFrame:(const char *)imgData DataSize:(NSInteger)size
{
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didReceiveJPEGDataFrame:DataSize:)]) {
        [self.delegate2 camera:self _didReceiveJPEGDataFrame:imgData DataSize:size];
    }
}

- (void)camera:(Camera *)camera didReceiveFrameInfoWithVideoWidth:(NSInteger)videoWidth VideoHeight:(NSInteger)videoHeight VideoFPS:(NSInteger)fps VideoBPS:(NSInteger)videoBps AudioBPS:(NSInteger)audioBps OnlineNm:(NSInteger)onlineNm FrameCount:(unsigned long)frameCount IncompleteFrameCount:(unsigned long)incompleteFrameCount
{
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didReceiveFrameInfoWithVideoWidth:VideoHeight:VideoFPS:VideoBPS:AudioBPS:OnlineNm:FrameCount:IncompleteFrameCount:)]) {
        [self.delegate2 camera:self _didReceiveFrameInfoWithVideoWidth:videoWidth VideoHeight:videoHeight VideoFPS:fps VideoBPS:videoBps AudioBPS:audioBps OnlineNm:onlineNm FrameCount:frameCount IncompleteFrameCount:incompleteFrameCount];
    }
}

- (void)camera:(Camera *)camera didChangeSessionStatus:(NSInteger)status
{
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didChangeSessionStatus:)]) {
        [self.delegate2 camera:self _didChangeSessionStatus:status];
    }
    
    if (self.sessionState == CONNECTION_STATE_UNKNOWN_DEVICE ||
        self.sessionState == CONNECTION_STATE_UNSUPPORTED ||
        self.sessionState == CONNECTION_STATE_CONNECT_FAILED) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
           
            [self disconnect];

        });
    }
}

- (void)camera:(Camera *)camera didChangeChannelStatus:(NSInteger)channel ChannelStatus:(NSInteger)status
{
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didChangeChannelStatus:ChannelStatus:)]) {
        [self.delegate2 camera:self _didChangeChannelStatus:channel ChannelStatus:status];
    }

    if (status == CONNECTION_STATE_WRONG_PASSWORD) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            
            [self stop:channel];
            
            usleep(500 * 1000);
            
            [self disconnect];
        });
    }
}

- (void)camera:(Camera *)camera didReceiveIOCtrlWithType:(NSInteger)type Data:(const char*)data DataSize:(NSInteger)size
{
    
    if (self.delegate2 && [self.delegate2 respondsToSelector:@selector(camera:_didReceiveIOCtrlWithType:Data:DataSize:)]) {
        [self.delegate2 camera:self _didReceiveIOCtrlWithType:type Data:data DataSize:size];
    }
    
    NSData *buf = [NSData dataWithBytes:data length:size];
    NSNumber *t = [NSNumber numberWithInt:type];    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: buf, @"recvData", t, @"type", self.uid, @"uid", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveIOCtrl" object:self userInfo:dict];
        
    if (type == (int)IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_RESP) {
        
        [arrayStreamChannel removeAllObjects];
        
        SMsgAVIoctrlGetSupportStreamResp *s = (SMsgAVIoctrlGetSupportStreamResp *)data;
        MyCamera* myCamera = (MyCamera*)camera;
		
        NSLog( @"==================================================" );
		NSLog( @"IOTYPE_USER_IPCAM_GETSUPPORTSTREAM_RESP total:%d", s->number );
        NSLog( @"==================================================" );
        if ( [myCamera getMultiStreamSupportOfChannel:0] ) {
            SStreamDef *def = malloc(size - (sizeof(s->number)));
            memcpy(def, s->streams, size - (sizeof(s->number)));
            
            for (int i = 0; i < s->number; i++) {
                
                SubStream_t ch;
                ch.index = def[i].index;
                ch.channel = def[i].channel;
				NSLog( @"\t[%d] index:%d channel:%d", i, ch.index, ch.channel );
                
                NSValue *objCh = [[NSValue alloc] initWithBytes:&ch objCType:@encode(SubStream_t)];
                [arrayStreamChannel addObject:objCh];
                [objCh release];
                
                if (def[i].channel != 0) {
                    // NSString *acc = [self getViewAccountOfChannel:0];
                    // NSString *pwd = [self getViewPasswordOfChannel:0];
                    
                    [self start:def[i].channel viewAccount:self.viewAcc viewPassword:self.viewPwd is_playback:FALSE];
                }
            }
            free(def);
        }
    }
	else if(type == (int)IOTYPE_USER_IPCAM_GET_TIMEZONE_RESP) {
        SMsgAVIoctrlTimeZone* p = (SMsgAVIoctrlTimeZone*)data;
				
		if( p->cbSize == sizeof(SMsgAVIoctrlTimeZone) ) {
			NSLog( @">>>> IOTYPE_USER_IPCAM_GET_TIMEZONE_RESP <OK>\n\tbIsSupportTimeZone:%d\n\tnGMTDiff:%d\n\tstrTimeZone:%@", p->nIsSupportTimeZone, p->nGMTDiff, ( strlen(p->szTimeZoneString) > 0 ) ? [NSString stringWithUTF8String:p->szTimeZoneString]:@"(null)" );
			bIsSupportTimeZone = p->nIsSupportTimeZone;
#if defined(IPCAMP) || defined(EasynPTarget)  || defined(BayitCam) || defined(MAJESTICIPCAMP)
            
#else
            bIsSupportTimeZone = NO;
#endif
			nGMTDiff = p->nGMTDiff;
			NSString* pTimeZoneStringFromDevice = nil;
			if( strlen(p->szTimeZoneString) > 0 )
				pTimeZoneStringFromDevice = [NSString stringWithUTF8String:p->szTimeZoneString];
    
            self.strTimeZone =pTimeZoneStringFromDevice ;
		}
	}
    
#ifdef SUPPORT_DROPBOX
    else if (type == IOTYPE_USER_IPCAM_GET_SAVE_DROPBOX_RESP) {
        
        SMsgAVIoctrlGetDropbox *s = (SMsgAVIoctrlGetDropbox *)data;
        
        self.isSupportDropbox = NO;
        self.isLinkDropbox = NO;
        
        if ( 1 == s->nSupportDropbox ){
            self.isSupportDropbox = YES;
                
            if ( 1 == s->nLinked){
                NSString *uuid = [[[ UIDevice currentDevice] identifierForVendor] UUIDString];
                if ( [uuid isEqualToString:[ NSString stringWithUTF8String:s->szLinkUDID]]){
                    self.isLinkDropbox = YES;
                }
            }
        }
    }
    
    else if (type == IOTYPE_USER_IPCAM_SET_SAVE_DROPBOX_RESP){
        //SMsgAVIoctrlSetDropbox *s = (SMsgAVIoctrlSetDropbox *)data;
        NSLog(@"get IOTYPE_USER_IPCAM_SET_SAVE_DROPBOX_RESP");
    }
#endif
    
}

//- (void)setVideoRecorderDelegate:(Camera *)camera {
//    NSLog(@"TEST!!!");
//    return;
//}

+(void)setcameraLoadAVGA:(NSString *)uid withIsLoad:(BOOL)isLoad{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSString *key=[NSString stringWithFormat:@"QVGALOAD%@",uid];
    [userDefault setBool:isLoad forKey:key];
}
+(BOOL)getCameraLoadQVGA:(NSString *)uid{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSString *key=[NSString stringWithFormat:@"QVGALOAD%@",uid];
    BOOL rsult= [userDefault boolForKey:key];
    return rsult;
}


+(NSString *)cameraQVGAKey:(NSString *)uid{
    return [NSString stringWithFormat:@"%@QVGA",uid];
}

+(void)setCameraQVGA:(NSInteger)v ca:(MyCamera *)camera{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSString *key=[MyCamera cameraQVGAKey:camera.uid];
    [userDefault setInteger:v forKey:key];
}
+(NSInteger)getCameraQVGA:(MyCamera *)camera{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSString *key=[MyCamera cameraQVGAKey:camera.uid];
    NSInteger v=[userDefault integerForKey:key];
    v=v==0?2:v;
    return v;
}
+(void)loadCameraQVGA:(MyCamera *)ca{
    NSInteger v=[MyCamera getCameraQVGA:ca];
    
    SMsgAVIoctrlSetStreamCtrlReq *quality = (SMsgAVIoctrlSetStreamCtrlReq *)malloc(sizeof(SMsgAVIoctrlSetStreamCtrlReq));
    memset(quality, 0, sizeof(SMsgAVIoctrlSetStreamCtrlReq));
    
    quality->channel = 0;
    quality->quality = v;
    
    [ca sendIOCtrlToChannel:0
                       Type:IOTYPE_USER_IPCAM_SETSTREAMCTRL_REQ
                       Data:(char *)quality
                   DataSize:sizeof(SMsgAVIoctrlSetStreamCtrlReq)];
    
    free(quality);
}

-(void)setCameraSummaryTime:(BOOL)yesOrNo{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    [userDefault setBool:yesOrNo forKey:[NSString stringWithFormat:@"cn.easynp.timezonesummary.%@",self.uid]];
}
-(BOOL)getCameraSummartTime{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    return [userDefault boolForKey:[NSString stringWithFormat:@"cn.easynp.timezonesummary.%@",self.uid]];
}
@end
