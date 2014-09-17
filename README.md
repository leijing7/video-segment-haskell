## Video Segmentation

###Segment Video

1. Put the source AVI files and the corresponding praat txt files into a folder.
2. Put the segment.exe into the same folder
3. Double click the segment.exe. This will use the default 200ms offset at the beginning
and end of each tone. If you want other offset time, it has to be run through the
command line and input the offset you want after the program name as a parameter.
The program will search the current directory and segment the videos into shor clips
according to the praat txt file. Note the avi file name must be the same with the
relevant txt file name except the extension. The step will generate 3 sub directories
for each video. One for the normal clip with audio and video; one for the audio only;
the last is for the video only.


Note: the process would take probably 1 hour for one single source video file.


###Make the Video with Still Image
1. double click the imageVideo.exe program. This program has a friendly Gui to display
the chosen still image.
2. Select the orignal source avi file. Then use the '<<''>>' button to chose the still image
to be put into the final clip. It only can browse the first 100 frames in the video.
3. After the image is selected, you can use the 'Preview Still Image' to make sure which
frame it is.
4. Finally, click the 'Generate Video' button. It will generate a sub directory in the source
video folder. All the video clips with the still image will be in that sub directory.
Note: It only can handle one video file once because of the still image selection.
