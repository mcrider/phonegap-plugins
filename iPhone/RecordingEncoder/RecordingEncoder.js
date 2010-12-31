/*
 *  This code is adapted from the work of Michael Nachbaur
 *  by Simon Madine of The Angry Robot Zombie Factory
 *  2010-05-04
 *  MIT licensed
*/

/**
 * This class converts the current audio recording to MP3 format
 * @constructor
 */
function RecordingEncoder() {
}

/**
 * Save the screenshot to the user's Photo Library
 */
RecordingEncoder.prototype.encodeRecording = function(recordingURL) {
    PhoneGap.exec("RecordingEncoder.encodeRecording", recordingURL);
};

PhoneGap.addConstructor(function()
{
	if(!window.plugins)
	{
		window.plugins = {};
	}
    window.plugins.recordingEncoder = new RecordingEncoder();
});
