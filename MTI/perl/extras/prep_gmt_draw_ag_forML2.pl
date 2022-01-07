#!/usr/bin/perl

#$MTIDIR="/disk2/yito/MTI_pgc/" ;
#$MTIDIR="/home/yito/MTI_pgc/" ;
$MTIDIR="/home/ehuesca/VLF/MTI/" ;
#$ddir="/home/ehuesca/VLF/out_dir/zp/" ; # Data directory, added by AG
####
$S2H="$MTIDIR"."perl/bat_sac2helm_ag2.pl" ;
$SINV="$MTIDIR"."perl/sub_tdmrf_inv_cmt_ag_forML2.pl" ;
$TGMT="$MTIDIR"."perl/tdmrf_gmt_out_ag_forML2.pl" ;
####
$fhead=$ARGV[0] ;
$ddir=$ARGV[1] ;

open(IN, "event_hypoinfo.list" )  ;
$line=<IN> ;
chop($line) ;
@data=split(/\s+/,$line) ;
$YYYY=$data[0]  ;
$MM=$data[1] ;
$DD=$data[2] ;
$hh=$data[3] ;
$mm=$data[4] ;
$ort=$data[5] ;
$lon=$data[6] ;
$lat=$data[7] ;
$dep=$data[8] ;
$vr=$data[10] ;
#print"$S2H $fhead cmt_stat.list $data[6] $data[7]\n" ;
#system"$S2H $fhead cmt_stat.list $data[6] $data[7]"  ;
# modified by AG, to add the data directory
print"$S2H $fhead cmt_stat.list $data[6] $data[7] $ddir\n" ;
system"$S2H $fhead cmt_stat.list $data[6] $data[7] $ddir"  ;

open(IN,"grid_inv2.prm") || die "Grid_inv.prm not found\n" ;
while(<IN>){
    if($_=~ /^TWIND/){
	$TWIND=$_ ;
    }elsif($_=~/^GFPATH/){
	$GFPATH=$_ ;
    }
}
close(IN) ;
#### Make prm_tdmrf_inv ##
# making input file to be used by 'sub_tdmrf_inv_cmt_ag.pl'--AG
open(OUT, ">prm_tdmrf_inv") ;
print OUT "DTIME 1\n" ;
printf OUT "BTIME %d\n",$ort-2 ;
print OUT "$TWIND" ;
print OUT "MAXTIME 4\n" ;
print OUT "DEPTH " ;
$startdep=$dep-10 ;
if($startdep<1){
    $startdep=1 ;
}
$enddep=$dep+10 ;
if($enddep>100){
    $enddep=100 ;
}
for($i=$startdep ; $i<=$enddep ; $i++){
    printf OUT "%d", $i ;
    if($i!=$enddep){
	print OUT "\," ;
    }else{
	print OUT "\n" ;
    }
}
print OUT "$GFPATH" ;
close(OUT) ;

# running 'sub_tdmrf_inv_cmt_ag.pl'--AG
# it calculate the best moment tensors for 5 seconds around the best origin time
# and 20 km around the best depth--AG
print "$SINV $YYYY $MM $DD $hh $mm $lon $lat\n" ;
system "$SINV $YYYY $MM $DD $hh $mm $lon $lat" ;
# it's main output is 'itr_res_inv.out'--AG

print "cp itr_res_inv.out itr_res_inv.out.all\n" ;
system "cp itr_res_inv.out itr_res_inv.out.all" ;
print "cp prm_tdmrf_inv prm_tdmrf_inv.all\n" ;
system "cp prm_tdmrf_inv prm_tdmrf_inv.all" ;
######## 
open(OUT, ">prm_tdmrf_inv") ;
print OUT "DTIME 1\n" ;
print OUT "BTIME $ort\n" ;
print OUT "$TWIND" ;
print OUT "MAXTIME 0\n" ;
print OUT "DEPTH $dep\n" ;
print OUT "$GFPATH" ;
close(OUT) ;
# running 'sub_tdmrf_inv_cmt_ag.pl' again for the best fit solution--AG
# this gives source parameters of the event listed in the main input file 'event_hypoinfo.list'--AG
print "$SINV $YYYY $MM $DD $hh $mm $lon $lat\n" ;
system "$SINV $YYYY $MM $DD $hh $mm $lon $lat" ;
# it's main output is 'itr_res_inv.out'--AG
### GMT part ###
$minlon=$lon-1.5 ;
$maxlon=$lon+1.5 ;
$minlat=$lat-1.0 ;
$maxlat=$lat+1.0 ;
$Ropt="-R$minlon/$maxlon/$minlat/$maxlat" ;
$Bopt="-B1f1/NesW" ;
$Dopt="-Di" ;
$minvr=$vr-30 ;
if($minvr<0){
    $minvr=0 ;
}
$maxvr=$vr+5 ;

$ropt="-r$minvr/$maxvr/$startdep/$enddep" ;
$bopt="-b10f10/nESw" ;
$intdmrf=sprintf("tdmrf_inv.in_%04d_%03d",$ort,$dep) ;
print "$TGMT $Ropt $Dopt  $Bopt $ropt $bopt -sdelta $intdmrf\n" ;
system "$TGMT $Ropt $Dopt  $Bopt $ropt $bopt -sdelta $intdmrf" ;

