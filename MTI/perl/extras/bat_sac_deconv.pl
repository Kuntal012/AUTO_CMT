#! /usr/bin/perl
#$MTIDIR="/disk2/yito/MTI_pgc" ;
$MTIDIR="/home/yito/MTI_pgc" ;
# Variable #
$sacdeconv="$MTIDIR"."/perl/sac_deconv.pl" ;
#############
$ENV{SACDIR}="/home/kao/eqklib2/world/sac2000" ;
$exesac="/home/kao/eqklib2/world/sac2000/bin/sac" ;
$ENV{SACAUX}="/home/kao/eqklib2/world/sac2000/aux" ;
###############
$filehead=$ARGV[0] ;
$inlist=$ARGV[1] ;

open(IN, $inlist) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    for($i=1 ; $i<=$#data ; $i++){
	$target=$filehead."$data[0]".".."."$data[$i]".".D.SAC" ;
	print "$sacdeconv $target -F0.02/0.05 -C$data[0]/$data[$i]\n" ;
	system "$sacdeconv $target -F0.02/0.05 -C$data[0]/$data[$i]" ;
	
    }
}
close(IN) ;





