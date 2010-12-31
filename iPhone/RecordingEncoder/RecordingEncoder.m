//
//  RecordingEncoder.m
//
//  Created by Matt Crider, Dec. 2010.
//  Copyright 2010 Pensive Industries
//  MIT licensed
//

#import "RecordingEncoder.h"

const UInt32 kSrcBufSize = 32768;

@implementation RecordingEncoder

- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options
{
	ExtAudioFileRef infile, outfile;
	// Get path to documents folder and append the audio file to it
	NSString* recordingURLString = [arguments objectAtIndex:0];
	if (recordingURLString == nil) {
		NSLog (@"Audio file not specified.");
		return;
	}
	
	// Get the full path to the audio file
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask ,YES );
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:recordingURLString];
	NSURL* recordingURL = [NSURL fileURLWithPath:path];

	NSLog (@"Starting audio conversion.");
	
	// Open the input file and load into 'infile'
	OSStatus err = ExtAudioFileOpenURL((CFURLRef)recordingURL, &infile);
	assert(infile);
	
	// Get the input format (i.e., the native recording format)
	AudioStreamBasicDescription inputFormat;
	bzero(&inputFormat, sizeof(inputFormat));
	UInt32 thePropertySize = sizeof(inputFormat);
	err = ExtAudioFileGetProperty(infile, kExtAudioFileProperty_FileDataFormat,
								  &thePropertySize, &inputFormat);
	
	// Define a 'converter format' to read from
	AudioStreamBasicDescription	converterFormat;
	converterFormat.mFormatID = kAudioFormatLinearPCM;
	converterFormat.mSampleRate = 44100.0;
	converterFormat.mChannelsPerFrame = 2;
	converterFormat.mBytesPerPacket = 4;
	converterFormat.mFramesPerPacket = 1;
	converterFormat.mBytesPerFrame = 4;
	converterFormat.mBitsPerChannel = 16;
	converterFormat.mFormatFlags = kAudioFormatFlagsNativeEndian |
	kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;	
	
	err = ExtAudioFileSetProperty(infile, kExtAudioFileProperty_ClientDataFormat,
								  sizeof(converterFormat), &converterFormat);
	
	// Define the output format
	AudioStreamBasicDescription outputFormat;
	outputFormat.mFormatID = kAudioFormatMPEG4AAC;
	outputFormat.mFormatFlags = kMPEG4Object_AAC_Main;
	outputFormat.mSampleRate = 44100.0;
	/*
	outputFormat.mChannelsPerFrame = 1;
	outputFormat.mBytesPerPacket = 0;
	outputFormat.mFramesPerPacket = 0;
	outputFormat.mBytesPerFrame = 0;
	outputFormat.mBitsPerChannel = 0;
	*/
	outputFormat.mChannelsPerFrame = 2;
	outputFormat.mBytesPerPacket = 4;
	outputFormat.mFramesPerPacket = 1;
	outputFormat.mBytesPerFrame = 4;
	outputFormat.mBitsPerChannel = 16;
	
	// Append .m4a to the URL to get the new URL
	NSURL* outputFileURL = [recordingURL URLByAppendingPathExtension:@"m4a"];
	
	// Create the output file (will erase existing files)
	err = ExtAudioFileCreateWithURL((CFURLRef)outputFileURL, kAudioFileM4AType, &outputFormat, NULL, kAudioFileFlags_EraseFile, &outfile);
	assert(outfile);
	
	// Enable converter when writing to the output file by setting the client
	// data format to the pcm converter we created earlier.
    err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ClientDataFormat,
								  sizeof(converterFormat), &converterFormat);
	
	// Set up the buffer to read and write from
	#define BUFFER_SIZE 4096
	UInt8 *buffer = NULL;	
	buffer = malloc(BUFFER_SIZE);
	assert(buffer);	
	
	AudioBufferList conversionBuffer;
	conversionBuffer.mNumberBuffers = 1;
	conversionBuffer.mBuffers[0].mNumberChannels = inputFormat.mChannelsPerFrame;
	conversionBuffer.mBuffers[0].mData = buffer;
	conversionBuffer.mBuffers[0].mDataByteSize = BUFFER_SIZE;
	
	// Iteratively read from the input buffer and write to the ouput buffer; Exits when 
	// there is nothing left in the input buffer
	while (TRUE) {
		conversionBuffer.mBuffers[0].mDataByteSize = BUFFER_SIZE;
		
		UInt32 frameCount = INT_MAX;
		
		if (inputFormat.mBytesPerFrame > 0) {
			frameCount = (conversionBuffer.mBuffers[0].mDataByteSize / inputFormat.mBytesPerFrame);
		}
		
		// Read a chunk of input
		err = ExtAudioFileRead(infile, &frameCount, &conversionBuffer);
		assert(!err);
		
		// If no frames were returned, conversion is finished
		if (frameCount == 0)
			break;
		
		// Write pcm data to output file
		err = ExtAudioFileWrite(outfile, frameCount, &conversionBuffer);
		assert(!err);

	}
}

@end
