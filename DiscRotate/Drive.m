//
//  Drive.m
//  DiscRotate
//
//  Created by georg on 28.09.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/storage/IOMediaBSDClient.h>
//#import <IOKit/storage/IOCDMediaBSDClient.h>
//#import <IOKit/storage/IODVDMediaBSDClient.h>
//#import <IOKit/storage/IOBDMediaBSDClient.h>

@interface Drive : NSObject
+ (int)open:(const char*)path;
+ (void)setSpeed:(UInt16)speed forPath:(NSString*)path withType:(NSString*)type;
+ (NSNumber*)getSpeedForPath:(NSString*)path withType:(NSString*)type;
@end

@implementation Drive

+ (int)open:(const char*)path
{
    int fd;
    fd = open(path, O_RDONLY);
    
    if(fd == -1){
        NSLog(@"Error opening device %s: ", path);
    }
    
    return fd;
}

// IOCDMedia::setSpeed(s)
// s - Speed to be used for data transfers, in kB/s.
// kCDSpeedMin specifies the minimum speed for all CD media (1X). kCDSpeedMax specifies the maximum speed supported in hardware.

+ (void)setSpeed:(UInt16)speed forPath:(NSString*)path withType:(NSString*)type
{
    char cpath[MAXPATHLEN];
    [path getFileSystemRepresentation:cpath maxLength:MAXPATHLEN-1];
    int fd = [self open:cpath];
    
    if([type isEqualToString:@"CD"]){
        if(ioctl(fd, DKIOCCDSETSPEED, &speed))
            NSLog(@"Error setting speed for %s", cpath);
    }
    else if([type isEqualToString:@"DVD"]){
        if(ioctl(fd, DKIOCDVDSETSPEED, &speed))
            NSLog(@"Error setting speed for %s", cpath);
    }
    else if([type isEqualToString:@"BD"]){
        if(ioctl(fd, DKIOCBDSETSPEED, &speed))
            NSLog(@"Error setting speed for %s", cpath);
    }
    
    close(fd);
}

+ (NSNumber*)getSpeedForPath:(NSString*)path withType:(NSString*)type
{
    UInt16 speed = 0;
    char cpath[MAXPATHLEN];
    [path getFileSystemRepresentation:cpath maxLength:MAXPATHLEN-1];
    int fd = [self open:cpath];
    
    if([type isEqualToString:@"CD"]){
        if(ioctl(fd, DKIOCCDGETSPEED, &speed))
            NSLog(@"Error getting speed for %s", cpath);
    }
    else if([type isEqualToString:@"DVD"]){
        if(ioctl(fd, DKIOCDVDGETSPEED, &speed))
            NSLog(@"Error getting speed for %s", cpath);
    }
    else if([type isEqualToString:@"BD"]){
        if(ioctl(fd, DKIOCBDGETSPEED, &speed))
            NSLog(@"Error getting speed for %s", cpath);
    }
    close(fd);
    
    return [NSNumber numberWithUnsignedShort:speed];
}

@end

