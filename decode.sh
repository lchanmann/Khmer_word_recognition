# decode.sh - decode with viterbi algorithm and generate hypothesis results

HVite \
 -T 1 -l '*' -i tests/$1/output_$2.mlf \
 -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
 -S tests/$1/mfclist_$2 -H models/models.mmf -w lm/word_network.lat \
 dictionary/dictionary.dct phones/all.phe > tests/$1/$2.log

cat tests/$1/output_$2.mlf >> tests/$1/hypothesis.mlf

HResults \
 -f -I labels/words.mlf /dev/null tests/$1/hypothesis.mlf \
 > tests/$1/result.log
