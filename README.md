# updatemediaformats
Simple bash script to convert recursively found media files to modern formats.   
By default this script runs RECURSIVE !   
This script update all found media files to newer more efficient formats:   
avif for images and x265 mp4 for videos.   
Convertions will be made by imagemagic and ffmpeg.   
Options:   
&ensp; &ensp; -h&ensp; &ensp; --help&ensp; &ensp; Show this text   
&ensp; &ensp; -n&ensp; &ensp; --non-recursive&ensp; &ensp; Don't search for videos in other folders   
&ensp; &ensp; -i&ensp; &ensp; --images&ensp; &ensp; Convert .jpg/.jpeg/.png to .avif   
&ensp; &ensp; -p&ensp; &ensp; --pngs&ensp; &ensp; Convert .png to .jpg   
&ensp; &ensp; -g&ensp; &ensp; --gifs&ensp; &ensp; Convert .gif to x265 mp4   
&ensp; &ensp; -m&ensp; &ensp; --mp4s&ensp; &ensp; Convert x264 to x265   
Custom convertions options:   
&ensp; &ensp; -ic=&ensp; &ensp; --images-config=    
&ensp; &ensp; -pc=&ensp; &ensp; --pngs-config=   
&ensp; &ensp; -gc=&ensp; &ensp; --gifs-config=   
&ensp; &ensp; -mc=&ensp; &ensp; --mp4s-config=   
    
\[by default, the script will run with -p -g -m options]   
