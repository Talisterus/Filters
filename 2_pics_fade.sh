#!/bin/bash
#FILES=/path/to/*

files=(*.jpg)
first_file="${files[0]}"
second_file="${files[1]}"
echo $first_file
echo $second_file
#echo $files
#echo "${files[1]}"

ffmpeg -y \
	-loop 1 -t 3 -i $first_file \
	-loop 1 -t 3 -i $second_file \
	-filter_complex "
		[1]fade=d=1:t=in:alpha=1,setpts=PTS-STARTPTS+2/TB[f0];
		[0][f0]overlay,format=yuv420p[v]
	" -map "[v]" \
	-movflags +faststart faded.webm
