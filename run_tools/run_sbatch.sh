name_of_run=$1
nframes=$2
output="/home/rcf-proj3/kl5/kengshil/tmp/output.webm"

# list of video sequences
seq_path="/home/rcf-proj3/kl5/kengshil/test_sequences/"
#declare -a seqs=("akiyo" "bus" "city" "crew" "foreman" "harbour" "ice" "mobile")
declare -a seqs=("akiyo" "bus" "city" "crew" "foreman" "harbour" "ice" "mobile")
declare -a br_array=("100" "300" "600" "1000" "1500" "2000" "2500" "3000")

mkdir results/${name_of_run}

for seq in "${seqs[@]}"
do
  seq_file=${seq_path}${seq}_cif.y4m
  # ./get_rd.sh "${name_of_run}_${seq}" ${seq_file} $nframes $3
  if [ -z "$3" ]; then
    prunemethod=""
  else
    prunemethod="_$3"
  fi;

  VPXENC="/home/rcf-proj3/kl5/kengshil/tmp/aomenc_$$"
  VPXDEC="/home/rcf-proj3/kl5/kengshil/tmp/amodec_$$"
  VPXSO="/home/rcf-proj3/kl5/kengshil/tmp/libaom.so.0"
  cp ./aomenc$prunemethod $VPXENC
  cp ./aomdec$prunemethod $VPXDEC

  trap 'echo "Exiting..."; rm -f ${VPXENC} ${VPXDEC}' EXIT

  rdfile=results/${name_of_run}/rdt_${name_of_run}_${seq}.txt
  input=${seq_file}

  echo $input

  if [ -z "$nframes" ]; then
    Limit=""
  else
    Limit="--limit=$nframes"
  fi;

  echo "Sequence: $input"

  for Bitrate in "${br_array[@]}"
  do
    command="time $VPXENC -o $output $input --codec=av1 --cpu-used=0 --threads=0 --profile=0 --lag-in-frames=25 --min-q=0 --max-q=63 --auto-alt-ref=1 --passes=1 --kf-max-dist=150 --kf-min-dist=0 --drop-frame=0 --static-thresh=0 --bias-pct=50 --minsection-pct=0 --maxsection-pct=2000 --arnr-maxframes=7 --arnr-strength=5 --sharpness=0 --undershoot-pct=100 --overshoot-pct=100 --tile-columns=0 --frame-parallel=0 --test-decode=warn -v --psnr --target-bitrate=$Bitrate $Limit"
    #echo $command
    echo " Target bitrate: $Bitrate"
    $command >results/${name_of_run}/br${Bitrate}_${name_of_run}.txt 2>&1 || { exit 1; }
    ls -al $output >>results/br${Bitrate}_${name_of_run}.txt
  done

  # collect information from BR files
  w=$(grep 'g_w' results/br${Bitrate[0]}_${name_of_run}.txt | grep -oP '[0-9]+')
  h=$(grep 'g_h' results/br${Bitrate[0]}_${name_of_run}.txt | grep -oP '[0-9]+')
  echo "$w $h $nframes" > $rdfile

  for Bitrate in "${br_array[@]}"
  do
    bpf=$(grep -oP '\K[0-9]+b/f' results/br${Bitrate}_${name_of_run}.txt)
    psnr=$(grep -oP '\KPSNR[^$]+' results/br${Bitrate}_${name_of_run}.txt)
    enctime=$(grep 'user' results/br${Bitrate}_${name_of_run}.txt | grep -oP '[^(]+' | grep 'user')
    echo $bpf >> $rdfile
    echo $psnr >> $rdfile
    echo $enctime >> $rdfile
  done

  # delete BR files
  rm results/${name_of_run}/br*_${name_of_run}.txt
done
