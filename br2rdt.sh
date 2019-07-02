#!/bin/bash
#
# br2rdt.sh
# collect results from br files and write rdt files 
# $1: name of the run
# $2: number of frames to encode
# $3: method (suffix of aomenc/aomdec files)

#!/bin/bash

name_of_run=$1
nframes=$2
method=$3

seq_path="/home/rcf-proj3/kl5/kengshil/test_sequences/"
declare -a br_array=("100" "300" "600" "1000" "1500" "2100" "2800")
declare -a seqs=("akiyo" "bowing" "bus" "city" "crew" "foreman" "harbour" "ice" "mobile" "news" "pamphlet" "paris" "soccer" "students" "waterfall")

for seq in "${seqs[@]}"
do

  rdfile=results/rdt_${name_of_run}_${seq}.txt
  # collect information from BR files
  w=$(grep 'g_w' results/br${Bitrate[0]}_$1.txt | grep -oP '[0-9]+')
  h=$(grep 'g_h' results/br${Bitrate[0]}_$1.txt | grep -oP '[0-9]+')
  echo "$w $h $nframes" > $rdfile

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
  #for Bitrate in "${br_array[@]}"
  #do
  #  rm results/br${Bitrate}_$1.txt
  #done

done

