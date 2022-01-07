#!/opt/linux/centos/7.x/x86_64/pkgs/perl/5.20.2/bin/perl
#$MTIDIR="/disk2/yito/MTI_pgc" ;
$MTIDIR="/rhome/kchau012/bigdata/Taiwan_New/MTI/" ;
# Variable #
$sacdeconv="$MTIDIR"."perl/sac_deconv_ah.pl" ;
#############
#$ENV{SACDIR}="/home/kao/eqklib2/world/sac2000" ;
#$exesac="/home/kao/eqklib2/world/sac2000/bin/sac" ;
#$ENV{SACAUX}="/home/kao/eqklib2/world/sac2000/aux" ;
###############
$filehead=$ARGV[0] ;
$inlist=$ARGV[1] ;
#$ddir="/auto/home/aghosh/Ito_codes/test_codes/Package_MTI/seisg/fnetjst_testrun/test/" ;
$ddir=$ARGV[2] ;
$rdir=$ddir."zp/" ;

open(IN, $inlist) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    for($i=1 ; $i<=$#data ; $i++){
	$target=$filehead."$data[0]".".."."$data[$i]".".D.SAC" ;
	print "$sacdeconv $target $ddir $rdir -F0.02/0.05 -C$data[0]/$data[$i]\n" ;
	system "$sacdeconv $target $ddir $rdir -F0.02/0.05 -C$data[0]/$data[$i]" ;
	
    }
}
close(IN) ;





