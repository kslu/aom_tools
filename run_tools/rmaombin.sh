rm aomenc_$1
rm aomdec_$1
if [ -f tools/aom_entropy_optimizer_$1 ]; then
  rm tools/aom_entropy_optimizer_$1
fi
