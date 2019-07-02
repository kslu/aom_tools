name_of_run=$1
nframes=$2

# list of video sequences
#seq_path="/home/kslugcp5151/test_sequences/"
#seq_path="/Users/kslu/Documents/test_sequences/"
seq_path="/usr/local/google/home/kslu/test_sequences/derfs/"

#declare -a seqs=("akiyo_cif.y4m" "bowing_cif.y4m" "bus_cif.y4m" "city_cif.y4m" "crew_cif.y4m" "foreman_cif.y4m" "harbour_cif.y4m" "ice_cif.y4m" "mobile_cif.y4m" "news_cif.y4m" "soccer_cif.y4m")
#declare -a seqs=("akiyo" "bus" "city" "crew" "foreman" "harbour" "ice" "mobile")
declare -a seqs=("bus" "city" "crew" "foreman" "harbour" "mobile")

for seq in "${seqs[@]}"
do
  seq_file=${seq_path}${seq}_cif.y4m
  #./get_rd.sh "${name_of_run}_${seq}" ${seq_file} $nframes $3
  ./get_rdt.sh "${name_of_run}_${seq}" ${seq_file} $nframes $3
done
