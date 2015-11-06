# pre.sh - preprocess data, dictionary, label files, 
#          and language model

# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc lm tmp logs

# generate scripts/wav2mfcc
ls -1d $WAV/* > scripts/wavlist
sed -e "s/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' scripts/wavlist > scripts/mfclist
paste scripts/wavlist scripts/mfclist > scripts/wav2mfcc

# feature extraction
HCopy -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy_train.log

# word -> phoneme level label generation
HLEd -T 1 -l '*/' -d dictionary/dictionary.dct -i labels/phoneme.mlf edfile.led labels/words.mlf > logs/hled.log

# phoneme list generation
cat labels/phoneme.mlf | grep '^[a-z]' | sort -u > phones/all.phe
cat phones/all.phe | grep -v '^sil' | sort -u > phones/all.phe.nosil
cat labels/words.mlf | grep -v '^[#".]'| sort -u > dictionary/dictionary.wrd
echo -e '!ENTER\n!EXIT' >> dictionary/dictionary.wrd

# dictionary.dct.withsil generation
cp dictionary/dictionary.dct dictionary/dictionary.dct.withsil
echo -e 'SIL\t[]\tsil' >> dictionary/dictionary.dct.withsil

# bigram language model generation
HLStats -T 1 -b lm/bigram.lm -o -t 1 dictionary/dictionary.wrd labels/words.mlf > logs/hlstats.log
HBuild -T 1 -n lm/bigram.lm dictionary/dictionary.wrd lm/bigram.lat > logs/hbuild.log

# clean up
rm -f tmp/*
