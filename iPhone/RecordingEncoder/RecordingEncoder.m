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

static Boolean IsAACHardwareEncoderAvailable(void)
{
    Boolean isAvailable = false;
	
    // get an array of AudioClassDescriptions for all installed encoders for the given format 
    // the specifier is the format that we are interested in - this is 'aac ' in our case
    UInt32 encoderSpecifier = kAudioFormatMPEG4AAC;
    UInt32 size;
	
    OSStatus result = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (result) { printf("AudioFormatGetPropertyInfo kAudioFormatProperty_Encoders result %lu %4.4s\n", result, (char*)&result); return false; }
	
    UInt32 numEncoders = size / sizeof(AudioClassDescription);
    AudioClassDescription encoderDescriptions[numEncoders];
    
    result = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, encoderDescriptions);
    if (result) { printf("AudioFormatGetProperty kAudioFormatProperty_Encoders result %lu %4.4s\n", result, (char*)&result); return false; }
    
    for (UInt32 i=0; i < numEncoders; ++i) {
        if (encoderDescriptions[i].mSubType == kAudioFormatMPEG4AAC && encoderDescriptions[i].mManufacturer == kAppleHardwareAudioCodecManufacturer) isAvailable = true;
    }
	
    return isAvailable;
}

/*- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options
{
	ExtAudioFileRef infile = NULL, outfile = NULL;
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
	UInt32 size = sizeof(inputFormat);
	memset(&inputFormat, 0, sizeof(AudioStreamBasicDescription));
	err = ExtAudioFileGetProperty(infile, kExtAudioFileProperty_FileDataFormat, &size, &inputFormat);
	
	// Define a 'converter format' to read from
	AudioStreamBasicDescription	converterFormat;
	size = sizeof(converterFormat);
	memset(&converterFormat, 0, sizeof(AudioStreamBasicDescription));
	converterFormat.mFormatID = kAudioFormatLinearPCM;
	/*converterFormat.mSampleRate = 44100;
	converterFormat.mChannelsPerFrame = 1;
	converterFormat.mBytesPerPacket = 2;
	converterFormat.mFramesPerPacket = 1;
	converterFormat.mBytesPerFrame = 2;
	converterFormat.mBitsPerChannel = 16;

	
	converterFormat.mSampleRate          = 44100;
	converterFormat.mFormatFlags         = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked; //kAudioFormatFlagIsLittleEndian
	converterFormat.mChannelsPerFrame    = 1;
	converterFormat.mBitsPerChannel      = 8 * sizeof(AudioSampleType);
	converterFormat.mFramesPerPacket     = 1;
	converterFormat.mBytesPerFrame       = sizeof(AudioSampleType);
	converterFormat.mBytesPerPacket      = sizeof(AudioSampleType);
	converterFormat.mReserved            = 0;
	size = sizeof(converterFormat);
	err = ExtAudioFileSetProperty(infile, kExtAudioFileProperty_ClientDataFormat, size, &converterFormat);
	
	// Define the output format
	AudioStreamBasicDescription outputFormat;
	size = sizeof(outputFormat);
	memset(&outputFormat, 0, sizeof(AudioStreamBasicDescription));

	outputFormat.mFormatID = kAudioFormatMPEG4AAC;
	outputFormat.mSampleRate = 44100;
	outputFormat.mChannelsPerFrame = 1;
	// Get the API to fill out the rest
	//err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &outputFormat);
	outputFormat.mFormatFlags = 0;
	outputFormat.mBytesPerPacket = 2; // must have a value or won't write apparently
	outputFormat.mFramesPerPacket = 0;
	outputFormat.mBytesPerFrame = 0;
	outputFormat.mChannelsPerFrame = 1;
	outputFormat.mBitsPerChannel = 0;
	outputFormat.mReserved = 0;
	
	//outputFormat.mBytesPerPacket = outputFormat.mChannelsPerFrame * 34;
	//outputFormat.mFormatFlags = kMPEG4Object_AAC_Main;`
	
	// Append .m4a to the URL to get the new URL
	NSURL* outputFileURL = [recordingURL URLByAppendingPathExtension:@"m4a"];
	
	
	// Create the output file (will erase existing files)
	err = ExtAudioFileCreateWithURL((CFURLRef)outputFileURL, kAudioFileM4AType, &outputFormat, NULL, kAudioFileFlags_EraseFile, &outfile);
	assert(outfile);
	
	// Enable converter when writing to the output file by setting the client
	// data format to the pcm converter we created earlier.
	size = sizeof(converterFormat);
	err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ClientDataFormat, size, &converterFormat);
	

/*	AudioConverterRef audioConverter;
	size = sizeof(audioConverter);
	ExtAudioFileGetProperty(outfile, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);

	
	
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
	
	// can we encode to AAC?
    if (IsAACHardwareEncoderAvailable()) {
		NSLog (@"AAC encoder is available.");
    } else {
		NSLog (@"No AAC encoder.");
		return;
    }
	
	// Iteratively read from the input buffer and write to the ouput buffer; Exits when 
	// there is nothing left in the input buffer
	while (TRUE) {
		conversionBuffer.mBuffers[0].mDataByteSize = BUFFER_SIZE;
		
		UInt32 frameCount = INT_MAX;
		
		if (inputFormat.mBytesPerFrame > 0) {
			frameCount = (conversionBuffer.mBuffers[0].mDataByteSize / converterFormat.mBytesPerFrame);
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

	}*/
	
/*	- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options
	{
		ExtAudioFileRef sourceFile = 0;
		ExtAudioFileRef destinationFile = 0;
		OSStatus        error = noErr;
		
		AudioStreamBasicDescription srcFormat, destFormat;
		UInt32 size = sizeof(srcFormat);
		
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
		
		error = ExtAudioFileOpenURL((CFURLRef) recordingURL, &sourceFile);
		if(error != noErr)
			NSLog(@"conversion error: %i", error);
		error = noErr;
		
		ExtAudioFileGetProperty(sourceFile, kExtAudioFileProperty_FileDataFormat, &size, &srcFormat);
		
		destFormat.mFormatID = kAudioFormatMPEG4AAC;
		destFormat.mSampleRate = 44100;
		destFormat.mFormatFlags = 0;
		destFormat.mBytesPerPacket = 2; // must have a value or won't write apparently
		destFormat.mFramesPerPacket = 0;
		destFormat.mBytesPerFrame = 0;
		destFormat.mChannelsPerFrame = 1;
		destFormat.mBitsPerChannel = 0;
		destFormat.mReserved = 0;
		
		//create the output file
		size = sizeof(destFormat);
		AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &destFormat);
		
		
		// Append .m4a to the URL to get the new URL
		NSURL* destinationURL = [recordingURL URLByAppendingPathExtension:@"m4a"];
		
		error = ExtAudioFileCreateWithURL((CFURLRef)destinationURL, kAudioFileM4AType, &destFormat, NULL, kAudioFileFlags_EraseFile, &destinationFile);
		if(error != noErr)
			NSLog(@"conversion error: %i", error);
		error = noErr;
		
		//canonical format
		AudioStreamBasicDescription clientFormat;
		clientFormat.mFormatID = kAudioFormatLinearPCM;
		clientFormat.mSampleRate = 44100;
		int sampleSize = sizeof(AudioSampleType);
		clientFormat.mFormatFlags = kAudioFormatFlagsCanonical;
		clientFormat.mBitsPerChannel = 8 * sampleSize;
		clientFormat.mChannelsPerFrame = 1;
		clientFormat.mFramesPerPacket = 1;
		clientFormat.mBytesPerPacket = sampleSize;
		clientFormat.mBytesPerFrame = sampleSize;
		clientFormat.mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
		
		//set the intermediate format to canonical on the source file for conversion (?)
		ExtAudioFileSetProperty(sourceFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
		ExtAudioFileSetProperty(destinationFile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);

		//get the converter
		AudioConverterRef audioConverter;
		size = sizeof(audioConverter);
		error = ExtAudioFileGetProperty(destinationFile, kExtAudioFileProperty_AudioConverter, &size, &audioConverter);
		if(error != noErr)
			NSLog(@"error getting converter: %i", error);
		error = noErr;
		
		/*UInt32 bitRate = 64000;   
		 error = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, sizeof(bitRate), &bitRate);
		 if(error != noErr)
		 NSLog(@"error setting bit rate: %i", error);
		 error = noErr;
		
		// set up buffers
		UInt32 bufferByteSize = 32768;
		char srcBuffer[bufferByteSize];
		
		NSLog(@"converting...");
		
		int i=0;
		while (true) {
			i++;
			AudioBufferList fillBufList;
			fillBufList.mNumberBuffers = 1;
			fillBufList.mBuffers[0].mNumberChannels = 1;
			fillBufList.mBuffers[0].mDataByteSize = bufferByteSize;
			fillBufList.mBuffers[0].mData = srcBuffer;
			
			// client format is always linear PCM - so here we determine how many frames of lpcm
			// we can read/write given our buffer size
			UInt32 numFrames = bufferByteSize / clientFormat.mBytesPerFrame;
			
			error = ExtAudioFileRead(sourceFile, &numFrames, &fillBufList); 
			if(error != noErr)
				NSLog(@"read error: %i run: %i", error, i);
			
			if (!numFrames) {
				// this is our termination condition
				error = noErr;
				break;
			}
			
			//this is the actual conversion
			error = ExtAudioFileWrite(destinationFile, numFrames, &fillBufList);
			
			if(error != noErr)
				NSLog(@"conversion error: %i run: %i", error, i);
		}
		
		if (destinationFile) ExtAudioFileDispose(destinationFile);
		if (sourceFile) ExtAudioFileDispose(sourceFile);
			
	}
*/

- (void)encodeRecording:(NSArray*)arguments withDict:(NSDictionary*)options
{
	
	// Get path to documents folder and append the audio file to it
	NSString* recordingURLString = [arguments objectAtIndex:0];
	//NSString* recordingURLString = @"1294635000251.caf";
	if (recordingURLString == nil) {
		NSLog (@"Audio file not specified.");
		return;
	}
	
	// Get the full path to the audio file
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask ,YES );
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:recordingURLString];
	
	// Add the 'caf' extension to the file (AVFramework can't tell what file it is without the extension)
	NSString *pathWithExt = [path stringByAppendingString:@".caf"];
	
	// Attempt the move
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	NSError *error = noErr;
	if ([fileMgr moveItemAtPath:path toPath:pathWithExt error:&error] != YES)
		NSLog(@"Unable to move file: %@", [error localizedDescription]);
	
	
	
	
	
	
	NSURL *assetURL = [NSURL fileURLWithPath:pathWithExt];
	AVURLAsset *songAsset = [[AVURLAsset alloc]initWithURL:assetURL options:nil];
//AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
	
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
										   initWithAsset:songAsset
										   presetName:AVAssetExportPresetAppleM4A];
	
	// Append .m4a to the URL to get the new URL
	NSURL *exportURL = [NSURL fileURLWithPath:path];
	NSURL* destinationURL = [exportURL URLByAppendingPathExtension:@"m4a"];

    exportSession.outputURL = destinationURL;
	//[exportSession setOutputFileType:@"com.apple.m4a-audio"];
	exportSession.outputFileType = AVFileTypeAppleM4A;

	//NSLog(@"%@", [exportSession supportedFileTypes]);
	//exportSession.outputFileType=[[exportSession supportedFileTypes] objectAtIndex:1];
	
	
	
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
		NSLog(@"status: %i for %@", exportSession.status, exportSession.outputURL);
		NSLog(@"ExportSessionError: %@", [exportSession.error localizedDescription]);
		[exportSession release];
    }];
	
	// Delete the original CAF file
	if ([fileMgr removeItemAtPath:pathWithExt error:&error] != YES)
		NSLog(@"Unable to delete file: %@", [error localizedDescription]);

}

@end
