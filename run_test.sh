# run_test.sh - run test on the estimated parameter of the HMM

# setup directory
mkdir -p tests

# create a clean container for test
DIR=tests/$(date +"%F.%H%M")
mkdir -p $DIR
rm -rf $DIR/*

# parameter learning
bash -v ./init.sh

# split mfclist for four parallel processing threads
P=4
split -l $(echo `grep ".*" -c scripts/mfclist`/$P+1 | bc) scripts/mfclist $DIR/mfclist_
# use numeric part sequence for splited mfclist
n=0
ls -1d $DIR/mfclist_* | while read line
do
  let n++
  mv -f $line $DIR/mfclist_$n
done

# execute decode.sh parallelly in the background
for p in `seq 1 1 $P`
do
  nohup bash -v decode.sh $DIR $p models/models.mmf &
done
