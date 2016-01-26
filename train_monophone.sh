# train_monophone.sh - train monophone model
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

# use mixture models
cp models/hmm_0/models.mmf models/hmm_2/models.mmf
bash -v ./increase_mixture.sh $mfclist phones/khmer.phe