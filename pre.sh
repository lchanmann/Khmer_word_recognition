#!/usr/bin/env sh

# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc tmp logs

# generate scripts/wav2mfcc
ls -1d $WAV/* > tmp/wavlist
sed -e "/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' tmp/wavlist > tmp/mfclist
paste tmp/wavlist tmp/mfclist > scripts/wav2mfcc

# feature extraction
HCopy -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy_trn.log

# clean up
rm -f tmp/*
