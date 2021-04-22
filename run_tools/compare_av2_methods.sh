# !/bin/bash
# compare_av2_methods.sh
# encode a video sequence with different bitrate levels
# to get a list of RD results
# $1: name of the run
# $2: input sequence
# $3: target bitrate
# $4: number of frames
# $5, $6, ... pruning methods to compare

VPXENC="/tmp/aomenc_rdtm_$$"
VPXDEC="/tmp/aomdec_rdtm_$$"
PERF="/google/data/ro/projects/perf/perf"

if [ -f $PERF ]; then
  PERFCMD="$PERF stat -e instructions:u"
else
  PERFCMD=""
fi
trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC}' EXIT

rdtmfile=results/rdtm_$1.txt
tmpenc=results/brtm_enc_$1.txt
tmpdec=results/brtm_dec_$1.txt
input=$2
cqlvl=$3
nframe=$4
output="/tmp/output_$$.webm"
dec_output="/tmp/output_dec_$$.y4m"

echo "Sequence: $input"
echo $input >$rdtmfile
echo "$cqlvl $nframe" >>$rdtmfile

shift 4

while [ $# -gt 0 ]
do
  prunemethod="_$1"
  echo "Method = $1"
  cp ./aomenc$prunemethod $VPXENC
  cp ./aomdec$prunemethod $VPXDEC

  enccmd="$PERFCMD time $VPXENC -o $output $input --codec=av1 --cpu-used=0 \
    --threads=0 --profile=0 --lag-in-frames=19 --min-qp=0 --max-qp=63 \
    --auto-alt-ref=1 --passes=1 --kf-max-dist=160 --kf-min-dist=0 \
    --drop-frame=0 --static-thresh=0 --arnr-maxframes=7 --arnr-strength=5 \
    --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 \
    --frame-parallel=0 --test-decode=warn -v --psnr --end-usage=q \
    --cq-level=$cqlvl --limit=$nframe"
  deccmd="$PERFCMD time $VPXDEC --progress --codec=av1 -o $dec_output $output"
  $enccmd >$tmpenc 2>&1 || { exit 1; }
  $deccmd >$tmpdec 2>&1 || { exit 1; }
  ls -al $output >>$tmpenc

  label=$(grep 'PSNR(Y)' $tmpenc)
  info=$(grep 'Summary:' $tmpenc)
  dectime=$(grep 'ecoded frames' $tmpdec)
  encinstrucs=$(grep 'instructions:u' $tmpenc | sed 's/[ \t]*$//')
  decinstrucs=$(grep 'instructions:u' $tmpdec | sed 's/[ \t]*$//')

  echo "=== method: $1 ===" >> $rdtmfile
  echo $label >> $rdtmfile
  echo $info >> $rdtmfile
  echo $dectime >> $rdtmfile
  if [ -f $PERF ]; then
    echo "ENC $encinstrucs" >> $rdtmfile
    echo "DEC $decinstrucs" >> $rdtmfile
  fi
  shift
done

# collect video w/h information from temp files
w=$(grep 'g_w' $tmpenc | grep -oP '[0-9]+')
h=$(grep 'g_h' $tmpenc | grep -oP '[0-9]+')
ex -sc "2i|$w $h" -cx $rdtmfile

# delete temp files
rm $tmpenc $tmpdec $output $dec_output
