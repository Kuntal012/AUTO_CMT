#!/usr/bin/perl

#$minlon=233; 
#$maxlon=236 ;
#$minlat=46 ;
#$maxlat=49  ;
#$ddeg=0.2;

## ARGV[0] file's head
$filehead=$ARGV[0] ;
## ARGV[1] prm file 
$prmfile=$ARGV[1] ;
### ARGV[2] YYYYY
$YYYY=$ARGV[2] ;
### ARGV[3] MM
$MM=$ARGV[3] ;
### ARGV[4] DD
$DD=$ARGV[4] ;
### ARGV[5] hh
$hh=$ARGV[5] ;
### ARGV[6] mm
$mm=$ARGV[6] ;
####################
#$MTIDIR="/disk2/yito/MTI_pgc" ;
$MTIDIR="/home/yito/MTI_pgc" ;
$S2H=$MTIDIR."/perl/bat_sac2helm.pl" ;
$MGI=$MTIDIR."/perl/make_grid_in.pl" ;
$GRD=$MTIDIR."/src/SPA_grid/tdmrf_inv_spa_grid";
####################
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

###
