cp aomenc aomenc_$1
cp aomdec aomdec_$1
if [ -f tools/aom_entropy_optimizer ]; then
  cp tools/aom_entropy_optimizer tools/aom_entropy_optimizer_$1
fi
