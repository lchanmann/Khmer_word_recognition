#!/usr/bin/env sh

# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc tmp logs

# generate scripts/wav2mfcc
ls -1d $WAV/* > scripts/wavlist
sed -e "s/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' scripts/wavlist > tmp/mfclist
paste scripts/wavlist tmp/mfclist > scripts/wav2mfcc

# feature extraction
HCopy -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy_trn.log

# clean up
rm -f tmp/*
