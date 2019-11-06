#!/bin/bash
#
# speedtest.sh
# script that simulates the AV1 nightly speed test
# $1: name of the run
# $2: method (suffix of aomenc/aomdec files)
# $3: extraparams

if [ -z "$2" ]; then
  method=""
else
  method="_$2"
fi;

extraparams=$3

# for HPC
#HOMEDIR="/home/rcf-proj3/kl5/kengshil"
# for Unix
HOMEDIR=""

VPXENC="${HOMEDIR}/tmp/aomenc_$$"
#VPXSO="${HOMEDIR}/tmp/libaom.so.0"
cp ./aomenc$method $VPXENC

trap 'echo "Exiting..."; rm -f ${VPXENC}' EXIT
#declare -a speed_array=("0" "1" "2" "3" "4")
declare -a speed_array=("0" "1" "2")

spfile=results/speed_$1.txt
input="/usr/local/google/home/kslu/test_sequences/hevc-set/BasketballDrill_832x480_50.y4m"
output="${HOMEDIR}/tmp/output.webm"

echo "Sequence: $input"

for speed in "${speed_array[@]}"
do
  echo "Speed $speed..."
  command="perf stat -e instructions:u $VPXENC -o $output $input --codec=av1 --cpu-used=$speed --fps=50/1 --skip=0 -p 2 --target-bitrate=800 --lag-in-frames=19 --profile=0 --limit=80 --enable-cdef=0 --min-q=0 --max-q=63 --auto-alt-ref=1 --kf-max-dist=150 --kf-min-dist=0 --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --frame-parallel=0 -t 1 --psnr --test-decode=warn -D"
  #echo $command
  $command >>results/tmpic_$1_sp$speed.txt 2>&1 || { exit 1; }
done

for speed in "${speed_array[@]}"
do
  inccnt=$(grep 'instructions' results/tmpic_$1_sp$speed.txt)
  runtime=$(grep 'time elapsed' results/tmpic_$1_sp$speed.txt)
  echo "Speed $speed" >> $spfile
  echo $inccnt >> $spfile
  echo $runtime >> $spfile
done

# delete temp files
for speed in "${speed_array[@]}"
do
  if [ -f results/tmpic_$1_sp$speed.txt ]; then
    rm results/tmpic_$1_sp$speed.txt
  fi
done
