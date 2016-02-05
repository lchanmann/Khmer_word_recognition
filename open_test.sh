# open_test.sh - run open test with one hold-out speaker
#
#   $1 : model (triphone | monophone)

# exit on error
set -e

if [ "$#" -ne "1" ]; then
  echo 'Usage: open_test.sh (triphone | monophone)' >&2
  exit 1
fi

# define variables
model=$1
hmmlist=phones/khmer.phe

# hmmlist for triphone
if [ "$model"=="triphone" ]; then
  hmmlist=phones/khmer_tied_triphone.phe
fi

# setup directory
mkdir -p tests

DIR=tests/$(date +"%F.%H%M").open_test.$model
mkdir -p $DIR

# leave one out
for n in `seq 1 1 14`
do
  cat scripts/mfclist | grep -v "spkr$n/" > scripts/mfclist_leaveout_trn_$n
  cat scripts/mfclist | grep "spkr$n/" > scripts/mfclist_leaveout_tst_$n

  # models training
  bash -v "./train_$model.sh" scripts/mfclist_leaveout_trn_$n

  # copy hmm models and mfclist to test container
  cp models/models.mmf $DIR/models$n.mmf
  cp scripts/mfclist_leaveout_tst_$n $DIR/mfclist_$n

  # decoding
  nohup bash -v ./decode.sh $DIR $n "$DIR/models$n.mmf" $hmmlist &
done
