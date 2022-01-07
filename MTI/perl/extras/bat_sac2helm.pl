#!/usr/bin/perl
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
$MTIDIR="/home/yito/MTI_pgc/" ;
$ENV{SACDIR}="/home/kao/eqklib2/world/sac2000" ;
$exesac="/home/kao/eqklib2/world/sac2000/bin/sac" ;
$ENV{SACAUX}="/home/kao/eqklib2/world/sac2000/aux" ;
$exes2h=$MTIDIR."src/sac2helm" ;
###
$s2s=$MTIDIR."SAC2SAC/sactosac" ;
###############
$filehead=$ARGV[0] ;
$inlist=$ARGV[1] ;
$lon=$ARGV[2] ;
$lat=$ARGV[3]  ;

open(IN, $inlist) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    for($i=1 ; $i<=$#data ; $i++){
	if($data[$i] =~ /E$/){
	    $targetE=$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}elsif($data[$i] =~ /N$/){
	    $targetN=$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}elsif($data[$i] =~ /Z$/){
	    $targetZ=$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}
    }
    print $exesac."\n" ;
    open(SAC,"|$exesac") ;
    print "read $targetE $targetN\n" ;
    print SAC "read $targetE $targetN\n" ;
    print "ch evla $lat evlo $lon\n" ;
    print SAC "ch evla $lat evlo $lon\n" ;
    print "rot\n" ;
    print SAC "rot\n" ;
    print "read more $targetZ\n" ;
    print SAC "read more $targetZ\n" ;
    ###
    print SAC "mul 100\n" ; # input cm
    ###
    print "write tmp2 tmp1 tmp3\n" ;
    print SAC "write tmp2 tmp1 tmp3\n" ;
    print SAC "quit\n" ;
    close(SAC) ;
    ########################################################
    $output=$data[0]."_helm.dat" ;
    print"$output\n" ;
    print"$exes2h out=$output cmp=3\n" ;
    system"$exes2h out=$output cmp=3" ;
#    die ;
}
close(IN) ;
