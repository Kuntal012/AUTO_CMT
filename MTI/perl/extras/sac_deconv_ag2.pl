#!/usr/bin/perl

### PERL #####
use Cwd ;
use Time::Local ;
#require "lib1.pl" ;
###############
#$ENV{SACDIR}="/home/kao/eqklib2/world/sac2000" ;
#$exesac="/home/kao/eqklib2/world/sac2000/bin/sac" ;
$exesac="/usr/local/sac/bin/sac";
#$ENV{SACAUX}="/home/kao/eqklib2/world/sac2000/aux" ;
#################
$cdir=getcwd() ;
print $cdir."\n" ;

$ddir=$ARGV[1];
$rdir=$ARGV[2];
$wavefile=$ddir."$ARGV[0]" ;


#die ;
#### defaults ##############
#@filter1=("2","8") ;
$deconvf=0 ;
############################
for($i=0 ; $i<=$#ARGV ; $i++){
    if($ARGV[$i] =~ /^-F/){
	$ARGV[$i] =~ s/^-F// ;
	@filter1=split(/\//,$ARGV[$i]) ;
    }elsif($ARGV[$i] =~ /^-C/){ ## station's code/channel's name
	$ARGV[$i] =~ s/^-C// ;
	@data=split(/\//,$ARGV[$i]) ;
	$stcd=$data[0] ;
	$strm=$data[1] ;
    }
    
}

print "FILTER $filter1[0] $filter1[1]\n" ;
print "$stcd $strm\n" ;
##############################
##################################################
###########################
###################################################
#open(CMD,"ls SAC\_PZs\_CN\_$stcd\_$strm\_\*|") ;
#open(CMD,"ls /auto/home/aghosh/Ito_codes/test_codes/Package_MTI/seisg/fnetjst_testrun/$stcd\_$strm\.z\*|") ;
open(CMD,"ls $rdir"."$stcd\_$strm\.z\*|") ;
$line=<CMD> ;
close(CMD) ;
print "POLEZERO FILE list $line" ;
chop($line) ;
$respf=$line ;

print "$respf\n" ;
print "$wavefile\n" ;

if( -e $wavefile ){
    print "Found $wavefile -->  ";
}else{
    print "Not Found $wavefile -->  " ;
}
if( -e $respf ){
    print "Found $respf\n" ;
}else{
    print "Not Found $respfq\n" ;
}

### read sac file ###
###############

#if($strm =~ /Z/){
#    $outtmp = "tmp_Z" ;
#}elsif($strm =~ /N/){
#    $outtmp ="tmp_N" ;
#}elsif($strm =~ /E/){
#    $outtmp ="tmp_E" ;
#}
##
####
$output=$wavefile."_deconv" ;
open(SAC, "|$exesac\n") ;
print  "r $wavefile\n" ;
print SAC "r $wavefile\n" ;
print SAC "rtr; taper\n" ;
## transfer's output in Displacement ###
print SAC "transfer from polezero s $respf to none freq 0.001 0.01 0.08 0.5\n" ;
#print SAC "transfer from polezero s $respf to none freq 0.001 0.01 15 20\n" ;
print "bp co $filter1[0] $filter1[1] p 2\n" ;
print SAC "bp co $filter1[0] $filter1[1] p 2\n" ;
print SAC "interpolate delta 1.0\n" ;
print SAC "w $output\n " ;
print SAC "quit\n" ;
close(SAC) ;
