#!/bin/bash

set -e

# Help
updatebanner () {
information="
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
\033[1;33m$(basename "$0")\033[0m [-n] [-i] [-p] [-g] [-m] [-f] [<PATH>]
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
    -mc=      --mp4s-config=
    
    [by default, the script will run with -p -g -m options]
"
}

# Variable declarations
jpegset="-verbose -format jpg -layers Dispose -resize 3000\>x3000\> -quality 75%"
avifset=""
mp4muteset="-y -c:v libx265 -crf 26 -preset medium -movflags +faststart"
mp4aacset="-y -c:v libx265 -crf 26 -preset medium -c:a aac -b:a 128k  -movflags +faststart"
mp4copyset="-y -c:v libx265 -crf 26 -preset medium -c:a copy -movflags +faststart"
updatebanner
declare -i i
chosen=()

# Script arguments
for k in "$@"; do
  case $k in
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
      avifset=${k#*=}
      shift
      ;;
    -pc=*|--pngs-config=*)
      jpegset=${k#*=}
      shift
      ;;
    -gc=*|--gifs-config=*)
      mp4muteset=${k#*=}
      shift
      ;;
    -mc=*|--mp4s-config=*)
      mp4aacset=${k#*=}
      mp4copyset=${k#*=}
      shift
      ;;
    -*)
      echo "Unknown option $k"
      help
      exit 1
      ;;
    *)
      if [ -d "$k" ];then
        cd "$k"
      else
        echo "Unknown input: $k"
        help
        exit 1
      fi
      ;;
  esac
done

# Information
if [ ${#chosen[@]} -eq 0 ];then
  chosen=("pngs" "gifs" "mp4s")
fi

updatebanner
echo -e "
$information

Following files are going to be conversed:
${chosen[*]}

Script will work from this point: \033[1;33m$PWD\033[0m"
if [ -z "$nonrecursive" ];then echo -e "\033[1;31m! RECURSIVE !\033[0m";fi

# Dependency check
depcheck() {
  for d in "$@";do
    if ! command -v "$d" &> /dev/null;then
      echo -e "\033[0;33m$d\033[0m could not be found"
      exit 3
    fi
  done
}

depcheck "ffmpeg" "magick" "mediainfo"

# Prompt for confirmation
read -rp "Are you ready to proceed? y/N:" -N 1
if  ! { [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; };then
  echo -e '\r'
  exit
fi
echo -e '\r'

bathconvertion() {
  local extensions="$1"
  local targetextension="$2"
  local convert="$3"
  local conversionoptions="$4"
  readarray -d '' fileslist < <(find "$PWD" $nonrecursive -type f -regextype posix-extended -regex "^.*\.(${extensions})$" -print0)
  echo -e "\033[1;33mConverted 0 from ${#fileslist[@]} files to ${targetextension}.\033[0m"

  i=0
  for f in "${fileslist[@]}"
  do
    newfile=$(sed -E "s/\.(${extensions})$/.${targetextension}/I" <<< "${f}")
    ($convert "$f" "$conversionoptions" "$newfile" ) || continue
    touch -r "$f" "$newfile"
    rm "$f"
    i+=1
    echo -e "\033[1;33mConverted $i from ${#fileslist[@]} files to ${targetextension}.\033[0m $f"
  done
}

imgconversion() {
  magick "$1" $2 "$3"
}

gifconversion() {
  ffmpeg -hide_banner -i "$1" $2  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$3"
}

mp4conversion() {
  local currentcodec
  local audioformat
  currentcodec=$(mediainfo --Output='Video;%Format%' "$1")
  if [ "$currentcodec" = "HEVC" ]; then
    return 1
  fi
  audioformat=$(mediainfo --Output='Audio;%Format%' "$1")
  readarray -d '' setarray < <(echo -e "$2")
  if [ "$audioformat" = "AAC" ]; then
    ffmpeg -hide_banner -i "$1" ${setarray[1]} "$3" || { rm "$3"; return 1; }
  elif [ -z "$audioformat" ]; then
    ffmpeg -hide_banner -i "$1" ${setarray[2]} "$3" || { rm "$3"; return 1; }
  else
    ffmpeg -hide_banner -i "$1" ${setarray[0]} "$3" || { rm "$3"; return 1; }
  fi
}

for c in "${chosen[@]}"; do
  case "$c" in
    pngs)
    bathconvertion "png" "jpg" imgconversion "$jpegset"
    ;;
    images)
    bathconvertion "jpg|jpeg|png" "avif" imgconversion "$avifset"
    ;;
    gifs)
    bathconvertion "gif" "gif.hevc.mp4" gifconversion "$mp4muteset"
    ;;
    mp4s)
    nonrecursive+=" -type f -name *.hevc.mp4 -prune -o"
    mp4set="$mp4aacset\0$mp4copyset\0$mp4muteset"
    bathconvertion "mp4|m4v" "hevc.mp4" mp4conversion "$mp4set"
    ;;
  esac
done

