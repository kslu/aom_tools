#!/bin/bash
#
# Copyright 2011 Google Inc. All Rights Reserved.
# Author: debargha@google.com (Deb Mukherjee)

if [ -z $4 ]; then
  method=""
else
  method="_$4"
fi

extraparams=$5

HOMEDIR=""
VPXENC="${HOMEDIR}/tmp/aomenc_$$"
VPXDEC="${HOMEDIR}/tmp/aomdec_$$"
#VPXSO="${HOMEDIR}/tmp/libaom.so.0"
ENTOPT="${HOMEDIR}/tmp/aom_entropy_optimizer_$$"

cp ./aomenc$method $VPXENC
cp ./aomdec$method $VPXDEC
if [ -f tools/aom_entropy_optimizer$method ]; then
  cp tools/aom_entropy_optimizer$method $ENTOPT
fi

input_yuv="${HOMEDIR}/tmp/input_$$.yuv"
output_yuv="${HOMEDIR}/tmp/output_av1_$$.yuv"

trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC} ${input_yuv} ${output_yuv}; if [ -f "${ENTOPT}" ]; then rm ${ENTOPT}; fi' EXIT

input=$1
output="${HOMEDIR}/tmp/output.webm"
output_y4m="${HOMEDIR}/tmp/output.webm.y4m"
echo $input

if [ -z "$3" ]; then
  Frames=""
  Limit=""
else
  Frames="-frames $3"
  Limit="--limit=$3"
fi;
if [ -z "$2" ]; then
  Bitrate="500"
else
  Bitrate="$2"
fi;

command="time $VPXENC -o $output $input --codec=av1 --cpu-used=0 --threads=0 --profile=0 --lag-in-frames=25 --min-q=0 --max-q=63 --auto-alt-ref=1 --passes=2 --kf-max-dist=150 --kf-min-dist=0 --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 --frame-parallel=0 --test-decode=warn -v --psnr --target-bitrate=$Bitrate $Limit $extraparams"

echo $command

$command || { exit 1; }

time $VPXDEC --progress --codec=av1 --i420 -o $output_yuv $output
time $VPXDEC --progress --codec=av1 -o $output_y4m $output

ls -al $output

#Resolution=$(ffmpeg -i $input $input_yuv -y 2>&1 | grep Stream | grep Video | head -n 1 | grep -oP ', \K[0-9]+x[0-9]+' | tr 'x' ' ')

#psnr_command="psnr -s $Resolution $Frames $input_yuv $output_yuv"
#echo $psnr_command
#$psnr_command || { exit 1; }

if [ -f $ENTOPT ] && [ -f counts.stt ]; then
  $ENTOPT counts.stt
  cp aom_entropy_optimizer_parsed_counts.log cstt$method.log
fi
