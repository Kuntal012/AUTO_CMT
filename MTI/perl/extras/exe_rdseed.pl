#!/usr/bin/perl
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
$MTIDIR="/home/yito/MTI_pgc/" ;
$exe=$MTIDIR."rdseed/rdseed.linux" ;
###
$infile=$ARGV[0] ;

open(IN, $infile) ;
while(<IN>){
    chop($_) ;
    $inseed=$_ ;
    print $inseed."\n" ;
    open(CMD, "|$exe") ;
    print CMD "$inseed\n" ;
    print CMD "\n" ; #stdout
    print CMD "\n" ; #vol
    print CMD "d\n" ;#print CMD "Rd\n" ;
    print CMD "\n" ;#summary 
    print CMD "\n" ;#station 
    print CMD "\n" ;#channel
    print CMD "\n" ;#network
    print CMD "\n" ;#Loc
    print CMD "1\n" ;#format
    print CMD "\n" ;#endtime
    print CMD "Y\n" ;#pole zero
    print CMD "0\n" ;#check reversal
    print CMD "E\n" ;#select data type 
    print CMD "\n" ; # start 
    print CMD "\n" ;#end
    print CDM "\n" ;#sample buffer
    print CMD "\n" ;#extract response
    print CMD "quit\n" ;#
    close(CMD) ;
 
    
}
close(IN) ;
