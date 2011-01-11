//
//  RecordingEncoder.h
//
//  By Matt Crider, December 2010.
//  Copyright 2010 Pensive Industries.
//  MIT licensed
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PhoneGapCommand.h"

@interface RecordingEncoder : PhoneGapCommand {
}

- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options;
@end
