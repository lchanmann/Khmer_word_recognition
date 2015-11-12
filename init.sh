# init.sh - HMM flat start initialization 

# create required directories
mkdir -p models/hmm_0 models/hmm_1 models/hmm_2

# flat-start initialization
HCompV \
 -T 1 -M models/hmm_0 \
 -C configs/hcompv.conf -m \
 -S scripts/mfclist models/proto \
 > logs/hcompv_hmm_0.log

# initialize each hmm with the global estimated mean and variance
head -n 3 models/hmm_0/proto > models/hmm_0/models.mmf
for phone in `cat phones/all.phe`
do
 tail -n 28 models/hmm_0/proto | sed -e 's/~h \"proto\"/~h \"'$phone'\"/g' >> models/hmm_0/models.mmf
done

# Baum-Welch parameter re-estimation
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 240.0 120.0 1920.0 \
 -S scripts/mfclist -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 180.0 90.0 1440.0 \
 -S scripts/mfclist -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S scripts/mfclist -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log

# update HMM parameters
HHEd \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 commands/sil.hed phones/all.phe \
 > logs/hhed_hmm_0.log

# parameter re-estimation
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S scripts/mfclist -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log
HERest \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S scripts/mfclist -I labels/phoneme.mlf phones/all.phe \
 > logs/herest_hmm_0.log

# viterbi alignment
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S scripts/mfclist -H models/hmm_0/models.mmf \
 dictionary/dictionary.dct.withsil phones/all.phe \
 > logs/hvite_hmm_0.log

# HERest \
#  -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/hmm_0/herest.log
# HERest \
#  -T 1 -H models/hmm_0/models.mmf -M models/hmm_0 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/hmm_0/herest.log


# cp models/hmm_0/models.mmf models/am2/models.mmf
# for num in `seq 2 2 16`
# do
#   echo "MU $num {*.state[2-4].mix}" > hed/mkmix.hed
#   HHEd \
#    -T 1 -H models/am2/models.mmf \
#    hed/mkmix.hed phe/khmer.phe \
#    > models/am2/hhed.$num.log

#   HERest \
#    -T 1 -H models/am2/models.mmf \
#    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#    -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#    > models/am2/herest.log

#   HERest \
#    -T 1 -H models/am2/models.mmf \
#    -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#    -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#    > models/am2/herest.log
# done


# HVite \
#  -T 1 -a -l '*' -I mlf/khmerwrd.mlf -i mlf/khmeralgn.mlf \
#  -C configs/hvite.cfg -m -b SIL -o SW -y lab \
#  -S scp/khmer.scp -H models/am2/models.mmf dct/khmer.dct.withsil phe/khmer.phe \
#  > models/am2/hvite.log

# HERest \
#  -T 1 -H models/am2/models.mmf -M models/am2 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/am2/herest.log
# HERest \
#  -T 1 -H models/am2/models.mmf -M models/am2 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/am2/herest.log

# HVite \
#  -T 1 -a -l '*' -I mlf/khmerwrd.mlf -i mlf/khmeralgn.mlf \
#  -C configs/hvite.cfg -m -b SIL -o SW -y lab \
#  -S scp/khmer.scp -H models/am2/models.mmf dct/khmer.dct.withsil phe/khmer.phe \
#  > models/am2/hvite.log

# HERest \
#  -T 1 -H models/am2/models.mmf -M models/am2 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/am2/herest.log
# HERest \
#  -T 1 -H models/am2/models.mmf -M models/am2 \
#  -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
#  -S scp/khmer.scp -I mlf/khmeralgn.mlf phe/khmer.phe \
#  > models/am2/herest.log

# cp models/am2/models.mmf models/models.mmf
