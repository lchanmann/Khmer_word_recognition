# pre.sh - preprocess data, dictionary, label files, 
#          and language model

# wav directory
WAV='wav'

# create required directories
mkdir -p mfcc lm tmp logs
for n in `seq 1 1 14`
do
  mkdir -p mfcc/spkr$n
done

# generate script files
ls -1d $WAV/*/* > scripts/wavlist
sed -e "s/^$WAV\//mfcc\//" -e 's/.wav$/.mfc/' scripts/wavlist > scripts/mfclist
paste scripts/wavlist scripts/mfclist > scripts/wav2mfcc

# feature extraction
HCopy -T 3 -C configs/hcopy.conf -S scripts/wav2mfcc > logs/hcopy.log

# # word -> phoneme level label generation
# HLEd -T 1 -l '*/' 
#  -d dictionary/dictionary.dct -i labels/phoneme.mlf \
#  commands/mkphn.led labels/words.mlf > logs/hled.log

# # phoneme list generation
# cat labels/phoneme.mlf | grep '^[a-z]' | sort -u > phones/khmer.phe
# cat phones/khmer.phe | grep -v '^sil' | sort -u > phones/khmer.phe.nosil

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
HParse dictionary/grammar lm/word_network.lat

# # bigram language model generation
# HLStats -T 1 -b lm/bigram.lm -o -t 1 dictionary/dictionary.wrd labels/words.mlf > logs/hlstats.log
# HBuild -T 1 -n lm/bigram.lm dictionary/dictionary.wrd lm/bigram.lat > logs/hbuild.log

# # phoneme -> triphone labels generation
# HLEd -T 1 -l '*/' \
#  -i labels/triphone.mlf -n phones/khmer_triphone.phe \
#  commands/mktri.led labels/phoneme.mlf > logs/hled.log

# # triphone list generation
# perl pl/mkful.pl phones/khmer.phe.nosil > phones/khmer_triphone_redund.phe
# perl pl/mkuniq.pl phones/khmer_tri_redund.phe phones/khmer_triphone_all.phe

# # phonetic question set generation for triphone clustering
# perl pl/mktrihed.pl phones/khmer.phe phones/khmer_triphone.phe > commands/khmer_mktri.hed
# cat commands/khmer_comtrehead.hed > commands/khmer_comtre.hed
# perl pl/mktrehed.pl TB 480.0 phones/khmer.phe >> commands/khmer_comtre.hed
# echo -e '\nTR 1' >> commands/khmer_comtre.hed
# echo -e '\nAU phones/khmer_triphone_all.phe' >> commands/khmer_comtre.hed
# echo -e '\nST khmer_com.tre' >> commands/khmer_comtre.hed
# echo -e '\nCO phones/khmer_tied_triphone.phe' >> commands/khmer_comtre.hed

# clean up
rm -rf tmp/*
