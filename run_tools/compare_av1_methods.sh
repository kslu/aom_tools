#!/bin/bash
# compare_av1_methods.sh
# encode a video sequence with different bitrate levels
# to get a list of RD results
# $1: name of the run
# $2: input sequence
# $3: target bitrate
# $4: number of frames
# $5, $6, ... pruning methods to compare

VPXENC="/tmp/aomenc_rdtm_$$"
VPXDEC="/tmp/aomdec_rdtm_$$"
trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC}' EXIT

rdtmfile=results/rdtm_$1.txt
tmpfile=results/brtm_$1.txt
input=$2
Bitrate=$3
nframe=$4
output="/tmp/output.webm"
dec_output="/tmp/output_dec.y4m"

echo "Sequence: $input"
echo $input >$rdtmfile
echo "$Bitrate $nframe" >>$rdtmfile

shift 4

while [ $# -gt 0 ]
do
  prunemethod="_$1"
  echo "Method = $1"
  cp ./aomenc$prunemethod $VPXENC
  cp ./aomdec$prunemethod $VPXDEC

  enccmd="time $VPXENC -o $output $input --codec=av1 --cpu-used=0 \
    --threads=0 --profile=0 --lag-in-frames=25 --min-q=0 --max-q=63 \
    --auto-alt-ref=1 --passes=1 --kf-max-dist=150 --kf-min-dist=0 \
    --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 \
    --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 \
    --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 \
    --frame-parallel=0 --test-decode=warn -v --psnr \
    --target-bitrate=$Bitrate --limit=$nframe"
  deccmd="time $VPXDEC --progress --codec=av1 -o $dec_output $output"
  $enccmd >$tmpfile 2>&1 || { exit 1; }
  $deccmd >>$tmpfile 2>&1 || { exit 1; }
  ls -al $output >>$tmpfile

  bpf=$(grep -oP '\K[0-9]+b/f' $tmpfile)
  psnr=$(grep -oP '\KPSNR[^$]+' $tmpfile)
  enctime=$(grep 'user' $tmpfile | grep -oP '[^(]+' | grep 'user')
  dectime=$(grep 'decoded frames' $tmpfile)

  echo "=== method: $1 ===" >> $rdtmfile
  echo $bpf >> $rdtmfile
  echo $psnr >> $rdtmfile
  echo $enctime >> $rdtmfile
  echo $dectime >> $rdtmfile

  shift
done

# collect video w/h information from temp files
w=$(grep 'g_w' $tmpfile | grep -oP '[0-9]+')
h=$(grep 'g_h' $tmpfile | grep -oP '[0-9]+')
ex -sc "2i|$w $h" -cx $rdtmfile

# delete temp files
rm $tmpfile $output $dec_output
