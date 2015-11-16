# run_test.sh - run test on the estimated parameter of the HMM

# create a clean container for test
DIR=$(date +"%F.%H%M%S")
mkdir -p tests/$DIR
rm -rf tests/$DIR/*

# split mfclist for parallel processing
P=4
split -l $(echo `grep ".*" -c scripts/mfclist`/$P+1 | bc) scripts/mfclist tests/$DIR/mfclist_
# use numeric part sequence for splited mfclist
n=0
ls -1d tests/$DIR/mfclist_* | while read line
do
  let n++
  mv -f $line tests/$DIR/mfclist_$n
done

# execute decode.sh parallelly in the background
for p in `seq 1 1 $P`
do
  nohup bash -v decode.sh $DIR $p &
done
