# decode.sh - decode with viterbi algorithm and generate hypothesis results

# HMM models
MODELS=$1/models$2.mmf
if [ $3 ]; then
  MODELS=$3
fi

# viterbi decoding
HVite \
 -T 1 -l '*' -i $1/output_$2.mlf \
 -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
 -S $1/mfclist_$2 -H $MODELS -w lm/word_network.lat \
 dictionary/dictionary.dct phones/all.phe > $1/$2.log

# collect viterbi scores
cat $1/output_$2.mlf >> $1/hypothesis.mlf

# generate result statistics
HResults \
 -f -I labels/words.mlf /dev/null $1/hypothesis.mlf \
 > $1/result.log
