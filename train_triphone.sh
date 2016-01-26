# train_triphone.sh - train monophone model
#
#   $1 : mfclist

# error on using unset variable
set -u
# exit on error
set -e

# define variables
mfclist=$1

# initialize models
bash -v ./init.sh $mfclist

# create triphone models from monophone
HHEd \
 -T 1 -H models/hmm_0/models.mmf -M models/hmm_1 \
 commands/khmer_mktri.hed phones/khmer.phe \
 > logs/hhed_1_hmm_1.log

# first 2x parameter re-estimation on triphone models
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_triphone.phe \
 > logs/herest_hmm_1.log
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 -s khmer_triphone.sta \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_triphone.phe \
 > logs/herest_hmm_1.log

# generate full and tied triphone models
HHEd \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 commands/khmer_comtre.hed phones/khmer_triphone.phe \
 > logs/hhed_2_hmm_1.log
cp models/hmm_1/models.mmf models/hmm_1/models_full.mmf
HHEd \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 commands/khmer_bkful.hed phones/khmer_tied_triphone.phe \
 > logs/hhed_3_hmm_1.log

# 2x parameter re-estimation on tied triphone models
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_tied_triphone.phe \
 > logs/herest_hmm_1.log
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_tied_triphone.phe \
 > logs/herest_hmm_1.log

# viterbi alignment
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $mfclist -H models/hmm_1/models.mmf \
 dictionary/dictionary.dct.withsil phones/khmer_tied_triphone.phe \
 > logs/hvite_hmm_1.log

# 2x parameter re-estimation after viterbi alignment
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_tied_triphone.phe \
 > logs/herest_hmm_1.log
HERest \
 -T 1 -H models/hmm_1/models.mmf -M models/hmm_1 \
 -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
 -S $mfclist -I labels/triphone.mlf phones/khmer_tied_triphone.phe \
 > logs/herest_hmm_1.log

# use mixture models
cp models/hmm_1/models.mmf models/hmm_2/models.mmf
bash -v ./increase_mixture.sh $mfclist phones/khmer_tied_triphone.phe