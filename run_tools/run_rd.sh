#!/bin/bash

name_of_run=$1
nframes=$2
method=$3

# create a temp sbatch file
sbfile="sb_${method}.sh"

printf "#!/bin/bash\n\n" > $sbfile
echo "#SBATCH --job-name=${name_of_run}" >> $sbfile
echo "#SBATCH --output sssnc_${name_of_run}.out.%j" >> $sbfile
echo "#SBATCH --error sssnc_${name_of_run}.err.%j" >> $sbfile
echo "#SBATCH --time=24:00:00" >> $sbfile
echo "#SBATCH --nodes=8" >> $sbfile
echo "#SBATCH --ntasks=8" >> $sbfile
echo "#SBATCH --cpus-per-task=1" >> $sbfile
echo "#SBATCH --mem 2gb" >> $sbfile
printf "\n" >> $sbfile

seq_path="/home/rcf-proj3/kl5/kengshil/test_sequences/"
declare -a seqs=("akiyo" "bus" "city" "crew" "foreman" "harbour" "ice" "mobile")

if [ ! -d results/cstt_${method} ]; then
  mkdir results/cstt_${method}
fi

for seq in "${seqs[@]}"
do
  seq_file=${seq_path}${seq}_cif.y4m
  echo "srun -N1 -n1 ./get_rd.sh ${name_of_run}_${seq} ${seq_file} $nframes $3 &" >> $sbfile
  wait
done

printf "wait" >> $sbfile

sb_command="sbatch --mem=1gb $sbfile"
echo $sb_command
$sb_command

mv $sbfile results/
#rm ~/tmp/*
