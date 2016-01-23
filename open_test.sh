# open_test.sh - run open test with one hold-out speaker
#

# setup directory
mkdir -p tests

DIR=tests/$(date +"%F.%H%M").open_test
mkdir -p $DIR
rm -rf $DIR/*

# pre-processing
bash -v ./pre.sh

# leave one out
for n in `seq 1 1 14`
do
  cat scripts/mfclist | grep -v "spkr$n/" > scripts/mfclist_leaveout_trn_$n
  cat scripts/mfclist | grep "spkr$n/" > scripts/mfclist_leaveout_tst_$n

  # parameter learning
  bash -v ./init.sh scripts/mfclist_leaveout_trn_$n

  # copy hmm models and mfclist to test container
  cp models/models.mmf $DIR/models$n.mmf
  cp scripts/mfclist_leaveout_tst_$n $DIR/mfclist_$n

  # decoding
  nohup bash -v ./decode.sh $DIR $n &
done
