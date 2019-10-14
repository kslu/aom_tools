#!/bin/bash
#
# get_rd.sh
# encode a video sequence with different bitrate levels
# to get a list of RD results
# $1: name of the run
# $2: input sequence
# $3: number of frames to encode
# $4: method (suffix of aomenc/aomdec files)

if [ -z "$4" ]; then
  method=""
else
  method="_$4"
fi;

# for HPC
#HOMEDIR="/home/rcf-proj3/kl5/kengshil"
# for Unix
HOMEDIR=""

VPXENC="${HOMEDIR}/tmp/aomenc_$$"
VPXDEC="${HOMEDIR}/tmp/amodec_$$"
#VPXSO="${HOMEDIR}/tmp/libaom.so.0"
ENTOPT="${HOMEDIR}/tmp/aom_entropy_optimizer_$$"
cp ./aomenc$method $VPXENC
cp ./aomdec$method $VPXDEC
if [ -f tools/aom_entropy_optimizer$method ]; then
  cp tools/aom_entropy_optimizer$method $ENTOPT
  if [ ! -d results/cstt${method} ]; then
    mkdir results/cstt${method}
  fi
fi

trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC} ${ENTOPT}' EXIT

#declare -a br_array=("200" "600")
#declare -a br_array=("100" "300" "600" "1000" "1500" "2000" "2500" "3000")
declare -a br_array=("100" "300" "600" "1000" "1500" "2100" "2800")
rdfile=results/rdt_$1.txt
input=$2
output="${HOMEDIR}/tmp/output.webm"
echo $input

if [ -z "$3" ]; then
  Limit=""
else
  Limit="--limit=$3"
fi;

echo "Sequence: $input"

for Bitrate in "${br_array[@]}"
do
  command="time $VPXENC -o $output $input --codec=av1 --cpu-used=0 --threads=0 --profile=0 --lag-in-frames=25 --min-q=0 --max-q=63 --auto-alt-ref=1 --passes=2 --kf-max-dist=1 --kf-min-dist=0 --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 --frame-parallel=0 --test-decode=warn -v --psnr --target-bitrate=$Bitrate $Limit"
  #echo $command
  echo " Target bitrate: $Bitrate"
  $command >results/br${Bitrate}_$1.txt 2>&1 || { exit 1; }
  ls -al $output >>results/br${Bitrate}_$1.txt
  if [ -f $ENTOPT ] && [ -f counts.stt ]; then
    $ENTOPT counts.stt
    cp counts.stt results/cstt${method}/counts${method}_br${Bitrate}_$1.stt
    cp aom_entropy_optimizer_parsed_counts.log results/cstt${method}/cstt${method}_br${Bitrate}_$1.txt
  fi
done

# collect information from BR files
w=$(grep 'g_w' results/br${Bitrate[0]}_$1.txt | grep -oP '[0-9]+')
h=$(grep 'g_h' results/br${Bitrate[0]}_$1.txt | grep -oP '[0-9]+')
echo "$w $h $3" > $rdfile

for Bitrate in "${br_array[@]}"
do
  bpf=$(grep -oP '\K[0-9]+b/f' results/br${Bitrate}_$1.txt)
  psnr=$(grep -oP '\KPSNR[^$]+' results/br${Bitrate}_$1.txt)
  enctime=$(grep 'user' results/br${Bitrate}_$1.txt | grep -oP '[^(]+' | grep 'user')
  echo $bpf >> $rdfile
  echo $psnr >> $rdfile
  echo $enctime >> $rdfile
done

# delete BR files
for Bitrate in "${br_array[@]}"
do
  rm results/br${Bitrate}_$1.txt
done
