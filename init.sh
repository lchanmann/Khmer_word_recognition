# init.sh - HMM flat start initialization 

# exit on error
set -e

# mfclist
mfclist=scripts/mfclist
if [ "$1" ]; then
  # $1 = [scripts/mfclist_leaveout_trn_{k} | scripts/mfclist_trn]
  mfclist=$1
fi

# create required directories
#   models/hmm_0 : initail model
#   models/hmm_1 : triphone model
#   models/hmm_2 : monophone model
mkdir -p models/hmm_0 models/hmm_1 models/hmm_2

# flat-start initialization
HCompV \
 -T 1 -M models/hmm_0 \
 -C configs/hcompv.conf -m \
 -S $mfclist models/proto \
 > logs/hcompv_hmm_0.log

# initialize each hmm with the global estimated mean and variance in HMM macro file
head -n 3 models/hmm_0/proto > models/hmm_0/models.mmf
for phone in `cat phones/khmer.phe`
do
 tail -n 28 models/hmm_0/proto | sed -e 's/~h \"proto\"/~h \"'$phone'\"/g' >> models/hmm_0/models.mmf
done

# Baum-Welch parameter re-estimation for 3 iterations
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 240.0 120.0 1920.0 \
 -S $mfclist -I labels/phoneme.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 180.0 90.0 1440.0 \
 -S $mfclist -I labels/phoneme.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/phoneme.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log

# update HMM parameters to fix silence model
HHEd \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 commands/sil.hed phones/khmer.phe \
 > logs/hhed_hmm_0.log

# 2x parameter re-estimation right after fixing silence model
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/phoneme.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/phoneme.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log

# viterbi alignment
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $mfclist -H models/hmm_0/models.mmf \
 dictionary/dictionary.dct.withsil phones/khmer.phe \
 > logs/hvite_hmm_0.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/phoneme_with_alignment.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/phoneme_with_alignment.mlf phones/khmer.phe \
 > logs/herest_hmm_0.log
