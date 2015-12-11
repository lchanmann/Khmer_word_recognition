# init.sh - HMM flat start initialization 

# mfclist
MFCLIST=scripts/mfclist
if [ "$1" ]
then
  # scripts/mfclist_leaveout_trn_{k}
  MFCLIST=$1
fi

# create required directories
mkdir -p models/hmm_0 models/hmm_1 models/hmm_2

# flat-start initialization
HCompV \
 -T 1 -M models/hmm_0 \
 -C configs/hcompv.conf -m \
 -S $MFCLIST models/proto \
 > logs/hcompv_hmm_0.log

# initialize each hmm with the global estimated mean and variance in HMM macro file
head -n 3 models/hmm_0/proto > models/hmm_0/models.mmf
for phone in `cat phones/all.phe`
do
 tail -n 28 models/hmm_0/proto | sed -e 's/~h \"proto\"/~h \"'$phone'\"/g' >> models/hmm_0/models.mmf
done

# Baum-Welch parameter re-estimation for 3 iterations
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 240.0 120.0 1920.0 \
 -S $MFCLIST -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 180.0 90.0 1440.0 \
 -S $MFCLIST -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $MFCLIST -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log

# update HMM parameters to fix silence model
HHEd \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 commands/sil.hed phones/all.phe \
 > logs/hhed_hmm_0.log

# 2x parameter re-estimation right after fixing silence model
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $MFCLIST -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $MFCLIST -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log

# viterbi alignment
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $MFCLIST -H models/hmm_0/models.mmf \
 dictionary/dictionary.dct.withsil phones/all.phe \
 > logs/hvite_hmm_0.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
 > logs/herest_hmm_0.log

# mixture models
cp models/hmm_0/models.mmf models/hmm_2/models.mmf
for num in `seq 2 2 16`
do
  echo "MU $num {*.state[2-4].mix}" > commands/mixture.hed
  HHEd \
   -T 1 -H models/hmm_2/models.mmf \
   commands/mixture.hed phones/all.phe \
   > logs/hhed_hmm_2.$num.log

  HERest \
   -T 1 -H models/hmm_2/models.mmf \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log

  HERest \
   -T 1 -H models/hmm_2/models.mmf \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log
done

# viterbi alignment for mixture model
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $MFCLIST -H models/hmm_2/models.mmf dictionary/dictionary.dct.withsil phones/all.phe \
 > logs/hvite_hmm_2.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log

# viterbi alignment one more time
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $MFCLIST -H models/hmm_2/models.mmf dictionary/dictionary.dct.withsil phones/all.phe \
 > logs/hvite_hmm_2.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $MFCLIST -I labels/phoneme_with_alignment.mlf phones/all.phe \
   > logs/herest_hmm_2.log

# use hmm_2/models.mmf as main MMF
cp models/hmm_2/models.mmf models/models.mmf
