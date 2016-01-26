# decode.sh - decode with viterbi algorithm and generate hypothesis results

# error on using unset variable
set -u
# exit on error
set -e

# define variables
DIR=$1
P=$2
MODELS=$3
HMMLIST=$4

# viterbi decoding
HVite \
 -T 1 -l '*' -i $DIR/output_$P.mlf \
 -z zoo -q Atvaldmnr -s 2.4 -p -1.2 \
 -S $1/mfclist_$2 -H $MODELS -w lm/word_network.lat \
 dictionary/dictionary.dct $HMMLIST > $DIR/$P.log

# collect viterbi scores
cat $1/output_$2.mlf >> $1/hypothesis.mlf

# generate result statistics
HResults \
 -f -I labels/words.mlf /dev/null $1/hypothesis.mlf \
 > $1/result.log
