# decode.sh - decode with viterbi algorithm and generate hypothesis results

HVite \
 -T 1 -l '*' -i $1/output_$2.mlf \
 -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
 -S $1/mfclist_$2 -H models/models.mmf -w lm/word_network.lat \
 dictionary/dictionary.dct phones/all.phe > $1/$2.log

cat $1/output_$2.mlf >> $1/hypothesis.mlf

HResults \
 -f -I labels/words.mlf /dev/null $1/hypothesis.mlf \
 > $1/result.log
