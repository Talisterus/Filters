#!/bin/bash
#FILES=/path/to/*
for f in *.jpg
do
#rodziel obrazy na klatki z przesuwających się jpgów
ffmpeg -f lavfi -i "color=white:d=2:s=1920x1080[background]; movie=$f[overlay]; [background][overlay]overlay='(W-w)/2:H-n*120' " img$f%04d.png

done

files=(img*.png)
echo "nazwa pierwszego pliku to "$files
numberoffiles=$(ls -l *.png | wc -l)
#firstfile= "$files"
echo "Numer of files is " $numberoffiles

#sprawdzam jakie są wysokość i szerokość pierwszego obrazka
width=$(identify -format "%w" $files)
height=$(identify -format "%h" $files)

echo "width is"$width
echo "height is"$height



#jak szeroki ma być pasek przesuwający się po ekranie, uśredniony do liczby całkowitej
#number_of_pixels_to_move_hor=$((("$height"+"$numberoffiles"-1)/"$height"))
number_of_pixels_to_move_hor=$(("$height"/"$numberoffiles"))
echo " numer of pixels to move horizontally is " $number_of_pixels_to_move_hor
#number_of_pixels_to_move_ver=$((("$width"+"$numberoffiles"-1)/"$width"))
number_of_pixels_to_move_ver=$(("$width"/"$numberoffiles"))
echo " numer of pixels to move vertically is " $number_of_pixels_to_move_ver
i=1
j=1
count_loop=0
horizontal_temporary_frame=$files
  vertical_temporary_frame=$files
#ffmpeg -r 1 -i $1 -r 1 "img%04d.png"
convert -size "$width"X1 canvas:transparent hor_video_base_frame.png
convert -size 1X"$height" canvas:transparent ver_video_base_frame.png


for f in img*.png
do
count_loop=$(($count_loop+1))
  echo "Processing $f file... ($count_loop of $numberoffiles)"
#  convert $f -crop  "$height"X"$number_of_pixels_to_move_hor"+0+$i -append "hor_video_"$f
#  convert $f -crop "$number_of_pixels_to_move_ver"X"$height"+$j+0 +append "ver_video_"$f
#chce zeby wycinek nadpisal sie na oryginalnej klatce i iterowal tak dalej
  
  #wytnij kawałek i obróć, wklej do hor_video_base_frame.png
  convert $f -crop "$width"X"$number_of_pixels_to_move_hor"+0+$i -rotate 180 hor_video_base_frame.png -append hor_video_base_frame.png

  #obróc nowy obrazek, narysuj linię w kolorze cyan, stwórz nowy obrazek
  convert $f \( hor_video_base_frame.png -rotate 180 \) \( -stroke cyan -draw "line 0,$i $width,$i" \) -composite "hor_video_"$count_loop.png
  #  convert $f \( hor_video_base_frame.png -rotate 180 \) \( -stroke cyan -draw "line 0,$i $width,$i" \) -composite "hor_video_%04d"

  #j.w. ale tym razem obrazek dzielony jest pionowo a nie poziomo
  convert $f -crop "$number_of_pixels_to_move_ver"X"$height"+$j+0 -rotate 180 ver_video_base_frame.png +append ver_video_base_frame.png

  #j.w.
  convert $f \( ver_video_base_frame.png -rotate 180 \) \( -stroke cyan -draw "line $j,0 $j,$height" \) -composite "ver_video_"$count_loop.png
  #  convert $f \( ver_video_base_frame.png -rotate 180 \) \( -stroke cyan -draw "line $j,0 $j,$height" \) -composite "ver_video_%04d"
  

#convert *.png -background none -mosaic gotowy.png
  #convert -size "$width"X"$height" canvas:transparent \(  $f -crop "$number_of_pixels_to_move_ver"X"$height"+$j+0 \) -geometry +$j+0 -composite "ver_video_"$f
  #convert $f -append test.png
#nie działa dodwanie do istniejącego pliku :(((
  i=$(($i+$number_of_pixels_to_move_hor))
  echo "moving $i pixels horizontally this turn"
  j=$(($j+$number_of_pixels_to_move_ver))
    echo "moving $j pixels vertically this turn"
  #echo $i
  #echo $width
  #echo $height
  #horizontal_temporary_frame="hor_video_"$f
done
#echo "Processing still horizontal image..."
#convert hor*.png -background none -mosaic gotowy_horizontal.png
#echo "Processing still vertical image..."
#convert ver*.png -background none -mosaic gotowy_vertical.png
echo "Processing horizontal video..."
ffmpeg -i "hor_video_%d.png" -r:v 25 -c copy -map 0:v:0 -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 28 -an hor_video.mp4
echo "Processing vertical video..."
ffmpeg -i "ver_video_%d.png" -r:v 25 -c copy -map 0:v:0 -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 28 -an ver_video.mp4
echo "Making temporary token video for testing"
ffmpeg -pattern_type glob -i "img*.png" -r:v 25 -c copy -map 0:v:0 -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 28 -an middle_video.mp4
echo "Making serial video"
ffmpeg -i hor_video.mp4 -i middle_video.mp4 -i ver_video.mp4 -filter_complex "[1:v][0:v]scale2ref=oh*mdar:ih[1v][0v];[2:v][0v]scale2ref=oh*mdar:ih[2v][0v];[0v][1v][2v]hstack=3,scale='2*trunc(iw/2)':'2*trunc(ih/2)'" final.mp4
echo "Deleting unnecesarry files..."
rm *.png
