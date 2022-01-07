#!/opt/linux/centos/7.x/x86_64/pkgs/perl/5.20.2/bin/perl
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
#$MTIDIR="/home/yito/MTI_pgc/" ;
$MTIDIR="/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/MTI/" ;
#$ENV{SACDIR}="/home/kao/eqklib2/world/sac2000" ;
#$exesac="/home/kao/eqklib2/world/sac2000/bin/sac" ;
#$ENV{SACAUX}="/home/kao/eqklib2/world/sac2000/aux" ;
$exesac="/rhome/kchau012/bigdata/Satoshi/sac/bin/sac" ;
$exes2h=$MTIDIR."src/sac2helm" ;
###
$s2s=$MTIDIR."SAC2SAC/sactosac" ;
###############
$filehead=$ARGV[0] ;
$inlist=$ARGV[1] ;
$lon=$ARGV[2] ;
$lat=$ARGV[3]  ;
$ddir=$ARGV[4] ;

open(IN, $inlist) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    for($i=1 ; $i<=$#data ; $i++){
	if($data[$i] =~ /E$/){
	    $targetE=$ddir.$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}elsif($data[$i] =~ /N$/){
	    $targetN=$ddir.$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}elsif($data[$i] =~ /Z$/){
	    $targetZ=$ddir.$filehead."$data[0]".".."."$data[$i]".".D.SAC_deconv" ;
	}
    }
    print $exesac."\n" ;
    open(SAC,"|$exesac") ;
    print SAC "read $targetE;ch kcmpnm LHR;read $targetN;ch kcmpnm LHT;\n";
    print "read $targetE $targetN\n" ;
    print SAC "read $targetE $targetN\n" ;
    print "ch evla $lat evlo $lon\n" ;
    print SAC "ch evla $lat evlo $lon\n" ;
    print SAC "synchronize\n";
    print "rot to gc\n" ;
    print SAC "rot to gc\n" ;
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
