#!/opt/linux/centos/7.x/x86_64/pkgs/perl/5.20.2/bin/perl

#
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
#$MTIDIR="/home/yito/MTI_pgc/" ;
$MTIDIR="/rhome/kchau012/bigdata/Taiwan_New/MTI/" ;
$stlist="cmt_stat.list" ;
#$prmf="grid_inv_ah.prm" ;
$prmf="grid_inv_ah.prm" ;
# $stattbl=$MTIDIR."prm/station.list" ;
$stattbl="station.list" ;
$deltaz=$MTIDIR."src/deltazimuth" ;
###
$YYYY=$ARGV[0]  ;
$MM=$ARGV[1] ;
$DD=$ARGV[2] ;
$hh=$ARGV[3] ;
$mm=$ARGV[4] ;
$lon=$ARGV[5]  ;
$lat=$ARGV[6] ;

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

#print "dtime is $dtime\n" ;
#print "maxtime is $maxtime\n" ;
#print "depths2 is $depths[2]\n" ;
#print "deplabn is $deplabn\n" ;
#print "btime is $btime\n" ;
#print "twind is $twind\n" ;
#print "gfpath is $gfpath\n" ;

#die ;

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
$stnm=$#stats+1 ; # number of stations

#print "stnm is $stnm\n" ;
#print "stats2 $stats[2]\n" ;

#die ;
###
open(IN,$stattbl) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    if($#data>=3){
	$stcd=$data[0] ;
	$stlon{$stcd}=$data[2] ;
	$stlat{$stcd}=$data[1] ;
    }

}
close(IN) ;

#line1 
print "$stnm $deplabn $dtime $maxtime $YYYY $MM $DD $hh $mm $lon $lat\n" ;
#observation
for($i=0 ; $i<$stnm ; $i++){
    $stcd=$stats[$i] ;
    $obsf=$stats[$i]."_helm.dat" ;
    $stcd=$stats[$i] ;
#    print "$deltaz -e$lon/$lat -s$stlon{$stcd}/$stlat{$stcd}\n"  ;
    open(CMD,"$deltaz -e$lon/$lat -s$stlon{$stcd}/$stlat{$stcd}|")  ;
    $line=<CMD> ;
    chop($line) ;
    #print "This Line - $line\n"; #added by Kuntal
    close(CMD) ;
    @data=split(/\s+/,$line) ;
    $delta=$data[0] ;
    $azimu=$data[1] ;
    print "$obsf $delta $azimu $btime $twind\n" ;
    $sdelta{$stcd}=sprintf("%03d",$delta+0.5) ;
}

#greenfunction
for($j=0; $j< $deplabn ; $j++){
    $sdep=sprintf("%03d",$depths[$j] ) ;
    for($i=0 ; $i<$stnm ; $i++){
	$stcd=$stats[$i] ;
	$gfname="$gfpath"."cs$sdelta{$stcd}d$sdep" ;
	print "$gfname 0 $twind $depths[$j]\n" ;
    }

}
