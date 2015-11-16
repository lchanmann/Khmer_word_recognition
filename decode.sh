# decode.sh - decode with viterbi algorithm and generate hypothesis results

HVite \
 -T 1 -z lat -l lab -i tests/$1/output_$2.mlf \
 -C configs/hvite.conf -q Atvaldmnr -s 2.4 -p -1.2 \
 -S tests/$1/mfclist_$2 -H models/models.mmf -w lm/bigram.lat \
 dictionary/dictionary.dct phones/all.phe > tests/$1/$2.log

cat tests/$1/output_$2.mlf >> tests/$1/hypothesis.mlf

HResults \
 -f -I labels/words.mlf /dev/null tests/$1/hypothesis.mlf \
 > tests/$1/result.log