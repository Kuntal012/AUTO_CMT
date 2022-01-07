#!/usr/bin/perl
use Cwd ;
$list=$ARGV[0] ;
$cdir=getcwd() ;

print $cdir."\n" ;

$exe="/home/yito/MTI_pgc/rdseed/rdseed.linux" ;
open(LIST, "$list") ;
while(<LIST>){
    chop($_) ;
    $inseed=$_ ;
    print "$inseed\n" ;
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
    print CMD "1\n" ;#endtime
    print CMD "Y\n" ;#pole zero
    print CMD "0\n" ;#check reversal
    print CMD "E\n" ;#select data type 
    print CMD "\n" ; # start 
    print CMD "\n" ;#end
    print CDM "\n" ;#sample buffer
    print CMD "\n" ;#extract response
    print CMD "quit\n" ;#
    close(CMD) ;
#    die ;
}
close(LIST) ;
