# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc tmp logs

# generate scripts/wav2mfcc
ls -1d $WAV/* > scripts/wavlist
sed -e "s/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' scripts/wavlist > tmp/mfclist
paste scripts/wavlist tmp/mfclist > scripts/wav2mfcc

# feature extraction
HCopy -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy_pre.log

# phoneme level label generation
HLEd -T 1 -l '*/' -d dictionary.dct -i phoneme.mlf hled.cmd words.mlf > logs/hled.log

# phoneme list generation
cat phoneme.mlf | grep '^[a-z]' | sort -u > all.phe
cat phoneme.mlf | grep -v '^(\#|\"|\.|sil)'| sort -u > all.phe.nosil
cat phoneme.mlf | grep -v '^(\#|\"|\.)'| sort -u > dictionary.wrd
echo -e '!ENTER\n!EXIT' >> dictionary.wrd

# # with-silence dictionary generation
# cp dct/khmer.dct dct/khmer.dct.withsil
# echo -e 'SIL\t[]\tsil' >> dct/khmer.dct.withsil

# # language model generation # should use only training data instead!!
# HLStats -T 1 -b lm/khmer_bi.lm -o -t 1 dct/khmer.wrd mlf/khmerwrd.mlf > lm/hlstats.log
# HBuild -T 1 -n lm/khmer_bi.lm dct/khmer.wrd lm/khmer_bi.lat > lm/hbuild.log

# clean up
rm -f tmp/*
