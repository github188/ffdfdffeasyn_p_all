//
//  CustomGridTableViewCellStyle2.m
//  PlugCam
//
//  Created by  on 2012/2/21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CustomGridTableViewCellStyle2.h"

@implementation CustomGridTableViewCellStyle2
@synthesize button1,button2,button3,button4,button5,button6;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [button1 release];
    [button2 release];
    [button3 release];
    [button4 release];
    [button5 release];
    [button6 release];
    [super dealloc];
}

@end
