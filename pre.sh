# pre.sh - preprocess data, dictionary, label files, 
#          and language model

# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc lm tmp logs

# generate script files
ls -1d $WAV/*/* > scripts/wavlist
sed -e "s/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' scripts/wavlist > scripts/mfclist
paste scripts/wavlist scripts/mfclist > scripts/wav2mfcc

# create mfcc directory
cat scripts/mfclist | grep -o "mfcc/spkr[0-9]*" | sort -u | while read dir; do
  mkdir -p $dir
done

# feature extraction
HCopy -A -D -V -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy.log

# vocabulary extraction
cat labels/words.mlf | grep -v '^[#".]' | sort -u > dictionary/dictionary.wrd
echo -e '!ENTER\n!EXIT' >> dictionary/dictionary.wrd

# dictionary.dct.withsil generation
cp dictionary/dictionary.dct dictionary/dictionary.dct.withsil
echo -e 'SIL\t[]\tsil' >> dictionary/dictionary.dct.withsil

# generate task grammar
cat labels/words.mlf | grep -v '^[#".]' | sort -u | perl -p -e 's/\n/ | /;' > tmp/words
echo '$word = '$(cat tmp/words | sed 's/ | $/;/') > dictionary/grammar
echo >> dictionary/grammar
echo '(!ENTER $word !EXIT)' >> dictionary/grammar

# convert task grammar into word network for recognizer
HParse -A -D -V dictionary/grammar lm/word_network.lat > logs/hparse.log

# # bigram language model generation
HLStats -T 4 -b lm/bigram.lm -o -t 1 dictionary/dictionary.wrd labels/words.mlf > logs/hlstats.log
HBuild -T 1 -n lm/bigram.lm dictionary/dictionary.wrd lm/bigram.lat > logs/hbuild.log

# clean up
rm -rf tmp/*
