# run_test.sh - run test on the estimated parameter of the HMM

# setup directory
mkdir -p tests

# create a clean container for test
DIR=tests/$(date +"%F.%H%M")
mkdir -p $DIR
rm -rf $DIR/*

MALES=( 3 4 6 8 9 10 13 14 )
FEMALES=( 1 2 5 7 11 12 )
TEST_MALE=${MALES[$(( RANDOM % ${#MALES[*]} ))]}
TEST_FEMALE=${FEMALES[$(( RANDOM % ${#FEMALES[*]} ))]}

# generate mfclist_trn and mfclist_tst
cat scripts/mfclist | grep -v -e "spkr$TEST_MALE/" -e "spkr$TEST_FEMALE/" > scripts/mfclist_trn
cat scripts/mfclist | grep -e "spkr$TEST_MALE/" -e "spkr$TEST_FEMALE/" > scripts/mfclist_tst

# parameter learning
bash -v ./init.sh scripts/mfclist_trn

# split mfclist_tst for four parallel processing threads
P=4
split -l $(echo `grep ".*" -c scripts/mfclist_tst`/$P+1 | bc) scripts/mfclist_tst $DIR/mfclist_
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
