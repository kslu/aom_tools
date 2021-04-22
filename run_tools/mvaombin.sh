mv aomenc_$1 aomenc_$2
mv aomdec_$1 aomdec_$2
if [ -f tools/aom_entropy_optimizer_$1 ]; then
  mv tools/aom_entropy_optimizer_$1 tools/aom_entropy_optimizer_$2
fi
