#!/bin/bash

set -e
updatebanner () {
information="\033[1;31m! By default this script runs RECURSIVE !\033[0m

This script update all found media files to newer more efficient formats: 
avif for images and x265 mp4 for videos.

Convertions will be made by: \033[1;33mimagemagic\033[0m and \033[1;33mffmpeg\033[0m with the following settings:
\033[1;33mimagemagic\033[0m:
png:     $jpegset
images:    $avifset
\033[1;33mffmpeg\033[0m:
gif:    $mp4muteset -vf 'scale=trunc(iw/2)*2:trunc(ih/2)*2'
x264 with aac sound: $mp4copyset
x264 with non-aac sound: $mp4aacset
"
}

help() {
echo -e "
\033[1;33m$(basename "$0")\033[0m [-n] [-i] [-g] [-m] [-f]
$information
\033[1;33mOptions\033[0m:
    -h        --help                   Show this text
    -n        --non-recursive          Don't search for videos in other folders
    -i        --images                 Convert .jpg/.jpeg/.png to .avif
    -p        --pngs                   Convert .png to .jpg
    -g        --gifs                   Convert .gif to x265 mp4
    -m        --mp4s                   Convert x264 to x265
    Custom convertions options:
    -ic=      --images-config= 
    -pc=      --pngs-config=
    -gc=      --gifs-config=
    --mc=     ---mp4s-config=
    
    [by default, the script will run with -p -g -m options]
"
}

jpegset="-verbose -format jpg -layers Dispose -resize 3000\>x3000\> -quality 75%"
avifset=""
mp4muteset=" -c:v libx265 -crf 26 -preset medium -movflags +faststart"
mp4aacset="-c:v libx265 -crf 26 -preset medium -c:a aac -b:a 128k  -movflags +faststart"
mp4copyset="-c:v libx265 -crf 26 -preset medium -c:a copy -movflags +faststart"
updatebanner
chosen=()
for i in "$@"; do
  case $i in
    -h|--help)
      help
      exit
      ;;
    -n|--non-recursive)
      nonrecursive="-maxdepth 1"
      shift
      ;;
    -i|--images)
      chosen+=("images")
      shift
      ;;
    -p|--pngs)
      chosen+=("pngs")
      shift
      ;;
    -g|--gifs)
      chosen+=("gifs")
      shift
      ;;
    -m|--mp4s)
      chosen+=("mp4s")
      shift
      ;;
    -ic=*|--images-config=*)
      avifset=${i#*=}
      shift
      ;;
    -pc=*|--pngs-config=*)
      jpegset=${i#*=}
      shift
      ;;
    -gc=*|--gifs-config=*)
      mp4muteset=${i#*=}
      shift
      ;;
    -mc=*|--mp4s-config=*)
      mp4aacset=${i#*=}
      mp4copyset=${i#*=}
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      help
      exit 1
      ;;
    *)
      ;;
  esac
done

if [ ${#chosen[@]} -eq 0 ];then
  chosen=("pngs" "gifs" "mp4s")
fi

if ! command -v ffmpeg &> /dev/null
then
    echo -e "\033[0;33mffmpeg\033[0m could not be found"
    exit 1
fi

if ! command -v magick &> /dev/null
then
    echo -e "\033[0;33mimagemagick\033[0m could not be found"
    exit 1
fi

declare -i i
updatebanner
echo -e "
$information

Following files are going to be conversed:
${chosen[@]}"
read -p "Are you ready to proceed? y/N:" -N 1
if  ! ( [ $REPLY == "y" ] || [ $REPLY == "Y" ] );then
  echo -e '\r'
  exit
fi
echo -e '\r'

# PNG to AVIF
if [[ " ${chosen[*]} " =~ " pngs " ]]; then
readarray -d '' imgslist < <(find ./ $nonrecursive -type f -iname "*.png" -print0)
echo -e '\033[1;33m'Converted 0 from ${#imgslist[@]} images.'\033[0m'

i=0
for f in "${imgslist[@]}"
do
  newfile=$(sed -E 's/\.png$/.jpg/I' <<< "$f")
  magick "$f" $jpegset "$newfile"
  touch -r "$f" "$newfile"
  rm "$f"
  i+=1
  echo -e '\033[1;33m'Converted $i from ${#imgslist[@]} images.'\033[0m' $f
done
fi

#images to AVIF
if [[ " ${chosen[*]} " =~ " images " ]]; then
readarray -d '' imgslist < <(find ./ $nonrecursive -type f -regextype posix-extended -regex "^.*\.(jpg|jpeg|png)$" -print0)
echo -e '\033[1;33m'Converted 0 from ${#imgslist[@]} images.'\033[0m'

i=0
for f in "${imgslist[@]}"
do
  newfile=$(sed -E 's/\.(jpg|jpeg|png)$/.avif/I' <<< "$f")
  magick "$f" $avifset "$newfile"
  touch -r "$f" "$newfile"
  rm "$f"
  i+=1
  echo -e '\033[1;33m'Converted $i from ${#imgslist[@]} images.'\033[0m' $f
done
fi

# GIF to x265
if [[ " ${chosen[*]} " =~ " gifs " ]]; then
readarray -d '' gifslist < <(find ./ $nonrecursive -type f  -iname "*.gif" -print0)
echo -e '\033[1;33m'Converted 0 from ${#gifslist[@]} gifs.'\033[0m'

i=0
for f in "${gifslist[@]}"
do
  ffmpeg -hide_banner -i "$f" $mp4muteset  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$f.hevc.mp4"
  touch -r "$f" "$f.hevc.mp4"
  rm "$f"
  i+=1
  echo -e '\033[1;33m'Converted $i from ${#gifslist[@]} gifs.'\033[0m' $f
done
fi

# x264 MP4 to x265
if [[ " ${chosen[*]} " =~ " mp4s " ]]; then
i=0
echo -e '\033[1;33m'Probing videos:'\033[0m'
# -size -100M
readarray -d '' vidslist < <(find ./ $nonrecursive -type f -iname "*.mp4" -print0)
for index in "${!vidslist[@]}" ; do [[ ${vidslist[$index]} =~ .hevc.mp4$ ]] && unset -v 'vidslist[$index]' ; done
vidslist=("${vidslist[@]}")
declare -i totaltoprobe=${#vidslist[@]}
echo $totaltoprobe videos to probe
declare -a vidstoconvert

for v in "${vidslist[@]}"
do
  currentcodec=$(ffprobe -loglevel error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1  "$v")
  if [ "$currentcodec" != "hevc" ]; then
    vidstoconvert+=("$v")
  fi
  i+=1
  echo -ne "$(( i*100/totaltoprobe ))%\r"
done
echo -e '\033[1;33m'Converted 0 from ${#vidstoconvert[@]} videos.'\033[0m'

i=0
for f in "${vidstoconvert[@]}"
do
  newfile=$(sed -E 's/\.mp4$/.hevc.mp4/I' <<< "$f")
  audioformat=$(ffprobe -loglevel error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1  "$f")
  if [ "$audioformat" = "aac" ]; then
    ffmpeg -hide_banner -i "$f" $mp4copyset "$newfile"
    touch -r "$f" "$newfile"
    rm "$f"
  elif [ -z "$audioformat" ]; then
    ffmpeg -hide_banner -i "$f" $mp4muteset "$newfile"
    touch -r "$f" "$newfile"
    rm "$f"
  else
    ffmpeg -hide_banner -i "$f" $mp4aacset "$newfile"
    touch -r "$f" "$newfile"
    rm "$f"
  fi
  i+=1
  echo -e '\033[1;33m'Converted $i from ${#vidstoconvert[@]} videos.'\033[0m' $f
done
fi
