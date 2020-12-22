for n in "$@" ; do
  rm aomenc_$n
  rm aomdec_$n
  if [ -f tools/aom_entropy_optimizer_$n ]; then
    rm tools/aom_entropy_optimizer_$n
  fi
done
