#!/usr/bin/perl
#
# make a .hed script to clone monophones in a phone list 
# 
# rachel morton 6.12.96
#
# updated by tz579 09.21.2012


if (@ARGV != 2) {
  print "usage: makehed monolist trilist\n\n"; 
  exit (0);
}

($monolist, $trilist) = @ARGV;

open(MONO, "@ARGV[0]");

print "CL $trilist\n\n";

while ($phone = <MONO>) {
   chop($phone);
   if ($phone ne "") { 
      print "TI T_$phone {(*-$phone+*,$phone+*,*-$phone).transP}\n";
   }
}
