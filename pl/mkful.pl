#!/usr/bin/perl

# This script will generate all possible monophones, biphones 
#	and triphones for cross-word system from monophones list
#
# TL 7/1997
#

if ( $#ARGV != 0 ) {
    die "usage: mkful.pl monophones_list.\n";
}

$datfile = $ARGV[0];
if ( ! -f $datfile ) {
   die "monophones list file $datfile not found. Aborting!\n";
}

open(DATFILE,"<$datfile") or die "Can't open file $datfile\n";
while (<DATFILE>) {
	($Fld1) = split(' ', $_);
	$ph{++$np} = $Fld1;
}

printf (("sil\n"));
$ph{++$np} = 'sil';
for ($i = 1; $i <= $np; $i++) {
#	printf "%s\n", $ph{$i};
	for ($j = 1; $j < $np; $j++) {
    printf "%s-%s\n%s+%s\n", $ph{$i}, $ph{$j}, $ph{$j}, $ph{$i};
    # $c = $c + 2;
		for ($k = 1; $k <= $np; $k++) {
      printf "%s-%s+%s\n", $ph{$i}, $ph{$j}, $ph{$k};
      #  ++$c;
		}
	}
}

# printf "%d\n", $c;

close (DATFILE);
