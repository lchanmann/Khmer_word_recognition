# increase_mixture.sh - Increase mixture components 
#
# Dependencies:
#     - models/hmm_2/models.mmf           : model to be estimated
#     - $hmmlist                          : phones list
#     - labels/words.mlf                  : word-level labels
#     - labels/phoneme_with_alignment.mlf : phoneme-level labels
#     - dictionary/dictionary.dct.withsil : dictionary file

# exit on error
set -e

if [ "$#" -ne "2" ]; then
  echo 'Usage: increase_mixture.sh $mfclist $hmmlist' >&2
  exit 1
fi

# mixture size
mixtures=16

# mfclist
mfclist=$1

# hmmlist
hmmlist=$2

for num in `seq 2 2 $mixtures`
do
  echo "MU $num {*.state[2-4].mix}" > commands/mixture.hed
  HHEd \
   -T 1 -H models/hmm_2/models.mmf \
   commands/mixture.hed $hmmlist \
   > logs/hhed_hmm_2.$num.log

  HERest \
   -T 1 -H models/hmm_2/models.mmf \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log

  HERest \
   -T 1 -H models/hmm_2/models.mmf \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log
done

# viterbi alignment for mixture model
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $mfclist -H models/hmm_2/models.mmf \
 dictionary/dictionary.dct.withsil $hmmlist \
 > logs/hvite_hmm_2.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log

# viterbi alignment one more time
HVite \
 -T 1 -a -l '*' -I labels/words.mlf -i labels/phoneme_with_alignment.mlf \
 -C configs/hvite.conf -m -b SIL -o SW -y lab \
 -S $mfclist -H models/hmm_2/models.mmf \
 dictionary/dictionary.dct.withsil $hmmlist \
 > logs/hvite_hmm_2.log

# 2x parameter re-estimation right after viterbi alignment
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log
HERest \
   -T 1 -H models/hmm_2/models.mmf -M models/hmm_2 \
   -C configs/herest.conf -w 1 -t 120.0 60.0 960.0 \
   -S $mfclist -I labels/phoneme_with_alignment.mlf $hmmlist \
   > logs/herest_hmm_2.log

# use hmm_2/models.mmf as main MMF
cp models/hmm_2/models.mmf models/models.mmf