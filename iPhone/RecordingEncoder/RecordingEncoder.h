//
//  RecordingEncoder.h
//
//  By Matt Crider, December 2010.
//  Copyright 2010 Pensive Industries.
//  MIT licensed
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <AVFoundation/AVAsset.h>

#import "PhoneGapCommand.h"
@interface RecordingEncoder : PhoneGapCommand {
}

- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options;
@end
