# get_rd.sh
# encode a video sequence with different bitrate levels
# to get a list of RD results
# $1: name of the run
# $2: input sequence
# $3: target bitrate
# $4: number of frames
# $5, $6, ... pruning methods to compare

VPXENC="/home/kslugcp5151/tmp/aomenc_rdtm"
VPXDEC="/home/kslugcp5151/tmp/amodec_rdtm"
trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC}' EXIT

rdtmfile=results/rdtm_$1.txt
tempfile=results/brtm_$1.txt
input=$2
Bitrate=$3
nframe=$4
output="/tmp/output.webm"

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

	command="time $VPXENC -o $output $input --codec=av1 --cpu-used=0 --threads=0 --profile=0 --lag-in-frames=25 --min-q=0 --max-q=63 --auto-alt-ref=1 --passes=1 --kf-max-dist=150 --kf-min-dist=0 --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 --frame-parallel=0 --test-decode=warn -v --psnr --target-bitrate=$Bitrate --limit=$nframe"
	$command >$tempfile 2>&1 || { exit 1; }
	ls -al $output >>$tempfile

  bpf=$(grep -oP '\K[0-9]+b/f' $tempfile)
  psnr=$(grep -oP '\KPSNR[^$]+' $tempfile)
  enctime=$(grep 'user' $tempfile | grep -oP '[^(]+' | grep 'user')

	echo "=== method: $1 ===" >> $rdtmfile
	echo $bpf >> $rdtmfile
	echo $psnr >> $rdtmfile
	echo $enctime >> $rdtmfile

	shift
done

# collect video w/h information from temp files
w=$(grep 'g_w' $tempfile | grep -oP '[0-9]+')
h=$(grep 'g_h' $tempfile | grep -oP '[0-9]+')
ex -sc "2i|$w $h" -cx $rdtmfile

# delete temp files
rm $tempfile
