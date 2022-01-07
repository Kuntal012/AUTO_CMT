#!/usr/bin/perl
use Time::Local;

### Modified in 2004/08/03  
### Add azimuth correction for Tile meter
### $GHR, "rot th angle" at SAC part 
### and set local time label ( localyear, localmonth etc) 
###
### INPUT FILE event_hypoinfo.list ;
###            Waveform in SAC format ;
###
###
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
$MTIDIR="/home/yito/MTI_pgc/" ;
$stlist="cmt_stat.list" ;
$prmf="prm_tdmrf_inv" ;
$stattbl=$MTIDIR."prm/station.list" ;
$deltaz=$MTIDIR."src/deltazimuth" ;

$TDMRF=$MTIDIR."src/tdmrf_inv" ;

$YYYY=$ARGV[0]  ;
$MM=$ARGV[1] ;
$DD=$ARGV[2] ;
$hh=$ARGV[3] ;
$mm=$ARGV[4] ;
$lon=$ARGV[5]  ;
$lat=$ARGV[6] ;
#####

####
open(IN,$prmf) ;
while(<IN>){
    if($_ =~ /DTIME/){
	chop($_) ;
	@data=split(/\s+/,$_) ;
	$dtime=$data[1] ;
    }elsif($_ =~ /MAXTIME/){
	chop($_) ;
	@data=split(/\s+/,$_) ;
	$maxtime=$data[1] ;
    }elsif($_=~ /DEPTH/){
	chop($_)  ;
	@data=split(/\s+/,$_) ;
	@depths=split(/\,/,$data[1]) ;
	$deplabn=$#depths+1 ;
    }elsif($_=~ /BTIME/){
	chop($_)  ;
	@data=split(/\s+/,$_) ;
	$btime=$data[1] ;
    }elsif($_=~ /TWIND/){
	chop($_)  ;
	@data=split(/\s+/,$_) ;
	$twind=$data[1] ;
    }elsif($_=~ /GFPATH/){
	chop($_)  ;
	@data=split(/\s+/,$_) ;
	$gfpath=$data[1] ;
    }

}
close(IN); 

#for($i=0 ; $i<=$#depths ; $i++){
#    print "$depths[$i]\n" ;
#}

open(IN,$stlist) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    push(@stats,$data[0]) ;
}
close(IN) ;
$stnm=$#stats+1 ;
####
open(IN,$stattbl) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    if($_ !~ /^\#/){
	$stcd=$data[0] ;
	$stlon{$stcd}=$data[2] ;
	$stlat{$stcd}=$data[1] ;	
    }

}
close(IN) ;
print "BTIME $btime, MAXTIME $maxtime\n";


#####################
############################
# DEPTH TABLE ####################################
#############################
###############################################################
###### MAKE tm_inv.in for tdmrf_inv ###########################
###############################################################
##############
$oo=0 ; $dd=0 ;
open( OUT2, ">itr_res_inv.out") ;
for( $oo=$btime ; $oo<=$btime+$maxtime ; $oo++){
    $onsets=sprintf( "%04d",$oo) ;
    for( $dd=0 ; $dd<=$#depths ; $dd++ ) {
	$itrlabel=sprintf( "%04d_%03d",$onsets,$depths[$dd] ) ;
	print $itrlabel,"\n" ;
	open( OUT,">tdmrf_inv.in_$itrlabel" ) ;
	printf OUT "%d %03d 1 1\n",$#stats+1,$depths[$dd] ;


	
	for($i=0 ; $i<=$#stats; $i++){
	    $stcd=$stats[$i] ;
	    
	    open(CMD,"$deltaz -e$lon/$lat -s$stlon{$stcd}/$stlat{$stcd}|")  ;
	    print "$deltaz -e$lon/$lat -s$stlon{$stcd}/$stlat{$stcd}\n" ;
	    $line=<CMD> ;
	    chop($line) ;
	    close(CMD) ;
	    @data=split(/\s+/,$line) ;
	    $delta=$data[0] ;
	    $azimu=$data[1] ;
	    $sdelta{$stcd}=sprintf("%03d",$delta+0.5) ;

	    $dfname=$stats[$i]."_helm.dat" ;
	    printf OUT "%s %1.1lf %1.1lf %d %d\n", 
	    $dfname,$delta,$azimu,$onsets,$twind ;
	}
	for($i=0 ; $i<=$#stats ; $i++){
	    $stcd=$stats[$i] ;
	    if($gfpath =~ /\/$/){
		$gfpath =~ s/\/$// ;
	    }
	    $greenfile=sprintf("%s/jp%03dd%03d",$gfpath,$sdelta{$stcd},$depths[$dd]) ;
	    printf OUT "%s 0 %d\n",
	    $greenfile,$twind ;
	}
	print OUT "1 10 5.00e-13\n" ;
	print OUT "0\n" ;
 	close(OUT) ;

	system "$TDMRF tdmrf_inv.in_$itrlabel > /dev/null" ;
#	system "$TDMRF tdmrf_inv.in_$itrlabel" ;
	system "cp tdmrf_inv.out tdmrf_inv.out_$itrlabel"  ;
	
	open( IN, "tdmrf_inv.out" ) ;
	while(<IN>){
	    if($_ =~ "TOTAL"){
		chop($_) ;
		@data=split(/\s+/,$_) ;
		$moment=$data[7]; 
		$clvd=$data[8] ;
		$str=$data[9] ;
		$dip=$data[10] ;
		$rak=$data[11] ;
	    }
	    if( $_ =~ "VR"){
		chop($_) ;
		@data=split(/\s+/,$_) ;
		$varred=$data[1] ;
	    }
	}
	close(IN) ;
	
	printf "ONSET %s DEPTH %s  strike %s  dip %s  rake %s CLVD %s Mo %s VR %s\n",
	$onsets,$depths[$dd],$str,$dip,$rak,$clvd,$moment,$varred ;
	printf OUT2 "%s %s %s %s %s %s %s %s\n",
	$onsets,$depths[$dd],$str,$dip,$rak,$clvd,$moment,$varred ;

    }
}
close(OUT2) ;








