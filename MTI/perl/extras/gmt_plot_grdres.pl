#!/usr/bin/perl

$gmtpath="/home/kao/eqklib2/world/GMT4.1.1/bin" ;

system"gmtset PAPER_MEDIA A4" ;

system"$gmtpath/psbasemap -R233/239/47/51 -B1f1 -JT236/49/16c -P -K -X2 -Y5> test.ps" ;
system"$gmtpath/pscoast -R -JT -Dh -O -P -W0.75p -G200/255/200 -S200/200/255 -K >>test.ps" ;

open(IN, "grid_tdmrf_inv_sel.out") ;
open(CMD, "|$gmtpath/psxy -R -JT -Sc0.2 -O -P -K >>test.ps") ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    print "$data[6] $data[7]\n" ;
    print CMD "$data[6] $data[7]\n" ;
}
close(CMD) ;
close(IN) ;

open(IN, "sort -k 11,11r grid_tdmrf_inv_sel.out|") ;
$line=<IN> ;
close(IN) ;

chop($line) ;
$data=split(/\s+/,$_) ;
print $line."\n" ;
open(CMD, "|$gmtpath/psmeca -R -JT -Sa1 -O -P -K >>test.ps") ;
print  "$data[6] $data[7] $data[8] $data[11] $data[12] $data[13] $data[9] 0 0\n" ;
print  CMD "$data[6] $data[7] $data[8] $data[11] $data[12] $data[13] $data[9] 0 0\n" ;
close(CMD) ; 
