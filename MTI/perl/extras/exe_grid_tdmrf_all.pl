#!/usr/bin/perl
use Time::Local ;

#### out put shleshold ##
$shd=30 ;
#####
## ARGV[0] file's head
$fileheadfile=$ARGV[0] ;
## ARGV[1] prm file 
$prmfile=$ARGV[1] ;
### ARGV[2] YYYYY
#$YYYY=$ARGV[2] ;
### ARGV[3] MM
#$MM=$ARGV[3] ;
### ARGV[4] DD
#$DD=$ARGV[4] ;
### ARGV[5] hh
#$hh=$ARGV[5] ;
### ARGV[6] mm
#$mm=$ARGV[6] ;
####################
#$MTIDIR="/disk2/yito/MTI_pgc" ;
$MTIDIR="/home/yito/MTI_pgc" ;
$S2H=$MTIDIR."/perl/bat_sac2helm.pl" ;
$MGI=$MTIDIR."/perl/make_grid_in.pl" ;
$GRD=$MTIDIR."/src/SPA_grid/tdmrf_inv_spa_grid";
####################
$ilab=0 ;
open(IN2, $fileheadfile) ;
while(<IN2>){
    chop($_) ;
    $filehead=$_ ;
    @data1=split(/\//,$filehead) ;
    @data=split(/\./,$data1[1]) ;
    $YYYY=$data[0] ;
    $jd=$data[1] ;
    $h=$data[2] ;
    $m=$data[3] ;
    $time=timelocal(0,0,0,1,0,$YYYY-1900) ;
    $time+=($jd-1)*86400+$h*3600+$m*60 ;
    ($sec,$mm,$hh,$DD,$MM,$YYYY,$wday)=localtime($time) ;
    $YYYY+=1900 ;
    $MM+=1 ;
    print "$YYYY $MM $DD $hh $mm\n" ;
#    die ;

    open(IN,$prmfile) ;
    while(<IN>){
	chop($_) ;
	if($_ =~ /^LON/){
	    @data=split(/\s+/,$_) ;
	    @lons=split(/\,/,$data[1]) ;
	}elsif( $_ =~ /^LAT/){
	    @data=split(/\s+/,$_) ;
	    @lats=split(/\,/,$data[1]) ;
	}elsif( $_ =~ /^DDEG/){
	    @data=split(/\s+/,$_) ;
	    $ddeg=$data[1] ;
	}
    }
    close(IN) ;
#    die ;
###
    for($lon=$lons[0] ;$lon<=$lons[1] ;$lon+=$ddeg){
	for($lat=$lats[0] ;$lat<=$lats[1] ;$lat+=$ddeg){
	    print "$S2H $filehead cmt_stat.list $lon $lat\n" ;
	    system "$S2H $filehead cmt_stat.list $lon $lat" ;
	    print "$MGI $YYYY $MM $DD $hh $mm $lon $lat > test.in\n" ;
	    system "$MGI $YYYY $MM $DD $hh $mm $lon $lat > test.in" ;
	    
	    print "$GRD test.in\n" ;
#	die ;
	    system "$GRD test.in" ;
#	print "cp grid_tdmrf_inv.out grid_tdmrf_inv.out.$lon.$lat\n" ;
#	system "cp grid_tdmrf_inv.out grid_tdmrf_inv.out.$lon.$lat" ;
	}
    }

#######
    $outf=sprintf("grid_tdmrf_inv_sel%03d_%04d%02d%02d%02d.out",$shd,$YYYY,$MM,$DD,$hh) ;
    print "OUTPUT FILE $outf $YYYY $MM $DD $hh\n" ;

    open(OUT, ">$outf") ;
    open(IN, "grid_tdmrf_inv.out") ;
    while(<IN>){
	chop($_) ;
	@data=split(/\s+/,$_) ;
	if($data[10]>$shd){
	    print OUT $_."\n" ;
	}
    }
    close(IN)  ;
    close(OUT) ;
    system "rm grid_tdmrf_inv.out" ;
#    die ;
###
    $ilab++ ;
}
close(IN2) ;
