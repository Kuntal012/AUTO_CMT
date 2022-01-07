#!/opt/linux/centos/7.x/x86_64/pkgs/perl/5.20.2/bin/perl
## GMT script for tdmrf_inv by Y.Ito 
## Modified 2004/09/03
##  Moment element is collect e.g Mrr -> Mrt ..
##  Addition of local Variance reduction
##
##
use IPC::Open2 ;
use Time::Local;

#####
#$MTIDIR="/disk2/yito/MTI_pgc/" ;
#$MTIDIR="/home/yito/MTI_pgc/" ;
#$gmtdir="/home/kao/eqklib2/world/GMT4.1.1/bin" ;

$MTIDIR="/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/MTI/" ;
$gmtdir="/opt/linux/centos/7.x/x86_64/pkgs/gmt/4.5.8/bin" ;
$sortflag=0 ;
#$stationlist=$MTIDIR."prm/station.list" ;
$stationlist="./station.list" ;
####


for($i=0; $i<=$#ARGV; $i++){
    if($ARGV[$i] =~ /^-R/){
        $ARGV[$i] =~ s/^-R//g;
	$mapropt=$ARGV[$i] ;
	@data=split(/\//,$mapropt) ;
	$mapjopt=sprintf("T%lf/4.5c",$data[0]*0.5+$data[1]*0.5 ) ;    
    }elsif($ARGV[$i] =~ /^-D/){
        $ARGV[$i] =~ s/^-D//g;
        $coastf=$ARGV[$i] ;
    }elsif($ARGV[$i] =~ /^-B/){
        $ARGV[$i] =~ s/^-B//g;
        $mapbopt=$ARGV[$i] ;
    }elsif($ARGV[$i] =~ /^-r/){
        $ARGV[$i] =~ s/^-r//g;
        $vrropt=$ARGV[$i] ;
    }elsif($ARGV[$i] =~ /^-b/){
        $ARGV[$i] =~ s/^-b//g;
        $vrbopt=$ARGV[$i] ;
    }elsif($ARGV[$i] =~ /^-l/){
        $ARGV[$i] =~ s/^-l//g;
        $lflag=$ARGV[$i] ;
    }elsif($ARGV[$i] =~ /^-s/){
        $ARGV[$i] =~ s/^-s//g;
        if($ARGV[$i]=~/delta/){
	    $sortflag=1 ;
	}elsif($ARGV[$i]=~/azimuth/){
	    $sortflag=2 ;
	}else{
	    $sortflag=0 ;
	}
    }elsif($ARGV[$i] !~ /^-/){
	$inprmfile=$ARGV[$i] ;
    }else{
	printf "tdmrf_gmt_out_pgc.pl [input_parameter_file]\n",
	printf "   -R[west/east/south/north] -D[resolution] -B[tickinfo]\n" ;
	printf "   -l[draw_wave_line_option 0 or 1] -rminvr/maxvr/mindep/maxdep\n" ;
	printf "   -b[tickinfo for VR vs DEP] -s[sort_option delta, azimuth]\n" ;
	exit(1) ;
    }
}

printf "LFLAG %d\n",$lflag ;
############
# reading the input file--AG
open( IN, $inprmfile )  || die "$inprmfile not Found" ;
$line=<IN> ;
chop($line ) ;
@data=split(/\s+/, $line ) ;
$stnum=$data[0] ;
$cdepth=$data[1] ;
#$mapopt=$data[2] ;
for($i=0 ; $i<$stnum; $i++){
    $line=<IN> ;
    chop($line) ;
    @data=split(/\s+/,$line) ;
    push( @kstation, $data[0] );
    $instation=$kstation[$i] ;
    $kdelta{$instation}=$data[1] ;
    $kazimuth{$instation}=$data[2] ;
    $kzcor{$instation}=$data[3] ;
    $kdleng{$instation}=$data[4] ;
}
## for debug
for($i=0 ; $i<=$#kstation ; $i++){
    $instation=$kstation[$i] ;
    print "###$kstation[$i]     $kdelta{$instation}     $kazimuth{$instation}\n" ;
}
###
# in our case, $sortflag=1--AG
if($sortflag==0){
    @station=$kstation ;
}elsif($sortflag==1){
    @station = sort{ $kdelta{$a} <=> $kdelta{$b}} @kstation  ;
}elsif($sortflag==2){
    @station = sort{ $kazimuth{$a} <=> $kazimuth{$b}} @kstation  ;
}

for($i=0 ; $i<$stnum ; $i++){
    $instation=$station[$i] ;
    push( @delta, $kdelta{$instation} ) ;
    push( @azimuth, $kazimuth{$instation}) ;
    push( @zcor, $kzcor{$instation}) ;
    push( @dleng, $kdleng{$instation}) ;
}

### no use parameter ###
for($i=0 ; $i<$stnum; $i++){
    $line=<IN> ;
    chop($line) ;
    @data=split(/\s+/,$line) ;
    push( @gfcn, $data[0] ) ;
    push( @gzcor, $data[1]) ;
    push( @gleng, $data[2]) ;
}
########################
close(IN) ;
# Done reading input file--AG

# Reading observed and synthetic seismograms
for($i=0; $i < $stnum ; $i++){
    $inputfile=sprintf( "%s_gmt.out", $station[$i]) ;
    print STDERR $inputfile,"\n" ;
    open( IN, $inputfile ) || die "$inputfile not Found $station[$i]" ;
    $line=<IN> ;
    chop($line) ;
    push( @maxamp, $line ) ;
    for( $j=0 ; $j < $dleng[$i] ; $j++){
	$line=<IN> ;
	chop($line) ;
	@data=split( /\s+/,$line ) ;
	push( @obs1, $data[0] ) ;
	push( @obs2, $data[2] ) ;
	push( @obs3, $data[4] ) ;
	push( @syn1, $data[1] ) ;
	push( @syn2, $data[3] ) ;
	push( @syn3, $data[5] ) ;
    }    
    close(IN) ;
}
print $#obs1," ",  $#obs2," ", $#obs3, "\n" ;
#################################################
### make Station Opsition file ##################
for($i=0 ; $i<$stnum ; $i++){
    @data=split(/_/,$station[$i] );
    print "station's name $data[0]\n" ;
    push( @stcd,$data[0] ) ;
}

unless ( -e $stationlist){
    die ;
}

open( IN, $stationlist);
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    for( $i=0 ; $i<$stnum ; $i++){
	if($data[0] =~ /$stcd[$i]/){
	    $slat{$stcd[$i]}=$data[1] ;
	    $slon{$stcd[$i]}=$data[2] ;
	}
    }
}
close(IN) ;

#################################################
# Start collecting information of source parameters of the best event
open( IN, "tdmrf_inv.out" ) ;
$line=<IN> ; #line 1
chop($line) ;
@data=split(/\s+/,$line) ;
$mtnum=$data[2] ;
$mtint=$data[3] ;
$smowt=$data[4] ;
#print "Mtnum ",$mtnum,"\n" ;
$line=<IN> ; #line 2

for($i=0; $i<$mtnum ; $i++){
    $line=<IN> ;
    chop($line) ;
    @data=split(/\s+/,$line) ;
    push(@smrr,$data[6]) ; #Mzz
    push(@smtt,$data[1]) ; #Mxx
    push(@smff,$data[4]) ; #Myy
    push(@smrt,$data[3]) ; #Mxz
    push(@smrf,-$data[5]) ; #-Myz
    push(@smtf,-$data[2]) ; #-Mxy
    push( @smom, $data[7] ) ;
    push( @sstr, $data[9] ) ;
    push( @sdip, $data[10] ) ;
    push( @srak, $data[11] ) ;
    print $smom[$i],"\n" ;
}
$line=<IN> ;
chop($line) ;
@data=split(/\s+/,$line) ;
$mrr=$data[6] ; #Mzz
$mtt=$data[1] ; #Mxx
$mff=$data[4] ; #Myy
$mrt=$data[3] ; #Mxz
$mrf=-$data[5] ; #-Myz
$mtf=-$data[2] ; #-Mxy
$tmom=$data[7] ; #Total Moment
$clvd=$data[8] ; # CLVD
$mstr=$data[9] ;
$mdip=$data[10] ;
$mrak=$data[11] ;

$line=<IN> ;
chop($line) ;
@data=split(/\s+/,$line) ;
$vr=$data[1] ;
print "VR ", $vr,"\n" ;

$line=<IN> ;
chop($line) ;
@data=split(/\s+/,$line) ;
for($i=0 ; $i<$stnum ;$i++){
    push(@bzcor, $data[$i+2]) ;
}
$line=<IN> ;
chop($line) ;
@data=split(/\s+/,$line) ;
for($i=0 ; $i<$stnum ;$i++){
    push(@lvr,$data[$i+1]) ;
}
close(IN) ;
# Opeing another file
open( IN, "event_hypoinfo.list") || die "event_hypoinfo.list Not Found" ;
$line=<IN> ;
chop($line) ;
@hypoinfo=split(/\s+/,$line) ;
close(IN) ;
$lon=$hypoinfo[6] ;
$lat=$hypoinfo[7] ;
$hypolabel=$hypoinfo[10] ;
$hypoinfo[0]-=1900 ;
$hypoinfo[1]-- ;
$uusec = &timegm(0,$hypoinfo[4],$hypoinfo[3],$hypoinfo[2],$hypoinfo[1],$hypoinfo[0]);
for($i=0,$sum=0; $i<$stnum ; $i++){
    $sum+=$bzcor[$i] ;
n}
$cmtime=sprintf("%d",$sum/$stnum) ;
$uusec+=$cmtime ;
($sec,$min,$hour,$day,$month,$year,$wday,$yday, $isdst) = gmtime($uusec);
$year += 1900; $month++;
# Finish collecting source parameters of the best event
###########################

############################
#open2( *READ, *WRITE, "psxy -R -Jx -M -O -P -K -W1p" ) ;
if($lflag==1){
    $baselength=1.5 ;
    $pagewave=20 ;
}else{
    $baselength=4.5 ;
    $pagewave=10 ;
}
#$lflag=1 ; # 2 lines mode ON = 1 OFF = 0
 
############################3
$fnetstnum=0 ;
$tiltstnum=0 ;

for( $pagen=0, $pagei=1,$np=0 ; $pagen<$stnum ; $pagen+=$pagewave, $pagei++){
    open( OUT, "> inputdata_gmt_p$pagei.tmp" ) ;
    open( OUT2,"> inputdata_gmt2_p$pagei.tmp") ;
    open( OUT3,"> inputdata_gmts_p$pagei.tmp") ;
    for( $i=$pagen,$linenum=0,$lflagout=0 ; ($i<$stnum)&&($i<$pagen+$pagewave)  ; $i++){
	$lengf=$baselength/$dleng[$i] ;
	
	if($lflagout==0){
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+4, $obs1[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+4, $syn1[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT ">\n" ;
	    printf OUT2 ">\n" ;
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+$baselength+4.25, $obs2[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+$baselength+4.25, $syn2[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT  ">\n" ;
	    printf OUT2  ">\n" ;
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+$baselength*2+4.5, $obs3[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+$baselength*2+4.5, $syn3[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT  ">\n" ;
	    printf OUT2  ">\n" ;
	    
	    $fnetstnum++ ;
	    
	    #### LABEL ######
	    printf OUT3 "%lf %lf 9 0 1 0 %s %s (%s)\n", 0.5, 7.6+$linenum*2,  $stcd[$i],$strm[$i],$snam{$stcd[$i]} ;
	    printf OUT3 "%lf %lf 9 0 1 0 delta: %1.0dkm\n", 0.8, 8.0+$linenum*2, $delta[$i] ;
	    printf OUT3 "%lf %lf 9 0 1 0 azimuth: %1.0d deg.\n", 0.8, 8.4+$linenum*2,  $azimuth[$i] ;
	    printf OUT3 "%lf %lf 9 0 1 0 Max.Amp: %1.2em\n", 0.8, 8.8+$linenum*2, $maxamp[$i]/100 ;
	    printf OUT3 "%lf %lf 9 0 1 0 V.R: %1.1lf\n", 0.8, 9.2+$linenum*2, $lvr[$i] ;
	    #################
	    if($lflag==1){
		$lflagout=1 ;
	    }else{
		$linenum++ ;
	    }
	}else{
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+13, $obs1[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+13, $syn1[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT ">\n" ;
	    printf OUT2 ">\n" ;
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+$baselength+13.25, $obs2[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+$baselength+13.25, $syn2[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT  ">\n" ;
	    printf OUT2  ">\n" ;
	    for($j=0; $j < $dleng[$i] ; $j++){
		printf OUT "%lf %lf\n",$j*$lengf+$baselength*2+13.5, $obs3[$j+$np]+8+$linenum*2 ;
		printf OUT2 "%lf %lf\n",$j*$lengf+$baselength*2+13.5, $syn3[$j+$np]+8+$linenum*2 ;
	    }
	    printf OUT  ">\n" ;
	    printf OUT2  ">\n" ;
	    
	    $fnetstnum++ ;
	    ### LABEL ######
	    printf OUT3 "%lf %lf 9 0 1 0 %s %s (%s)\n", 9, 7.6+$linenum*2, $stcd[$i],$strm[$i],$snam{$stcd[$i]}  ;
	    printf OUT3 "%lf %lf 9 0 1 0 delta: %1.0dkm\n", 9.3, 8.0+$linenum*2, $delta[$i] ;
	    printf OUT3 "%lf %lf 9 0 1 0 azimuth: %1.0d deg.\n", 9.3, 8.4+$linenum*2,  $azimuth[$i] ;
	    printf OUT3 "%lf %lf 9 0 1 0 Max.Amp: %1.2em\n", 9.3, 8.8+$linenum*2, $maxamp[$i]/100 ;
	    printf OUT3 "%lf %lf 9 0 1 0 V.R: %1.1lf\n", 9.3, 9.2+$linenum*2, $lvr[$i] ;
	    #################
	    $lflagout=0 ;
	    $linenum++ ;
	}
	printf OUT ">\n" ;
	printf OUT2 ">\n" ;
	$np+=$dleng[$i] ;
	
	
	
	
    }
    close(OUT) ;
    close(OUT2) ;
    close(OUT3) ;
}    

##########label ###
open( OUT, "> inputdata_gmt2_1.tmp") ;
printf OUT "0.5 1.0 13 0 1 0 %04d/%02d/%02d   %02d:%02d:%02d \n", $year,$month,$day,$hour,$min,$sec  ;
printf OUT "0.5 1.5 13 0 1 0 %1.4lf   %1.4lf   %1.0lfkm Mw %1.1lf\n", 
    $lon, $lat, $cdepth, (log($tmom)/log(10)-9.1)/1.5 ;
close(OUT) ;

open( OUT, "> inputdata_gmt2_2.tmp") ;
printf OUT "%lf 6.5 10 0 1 2 %d sec.\n", 4+$baselength/2, $dleng[0] ;
printf OUT "%lf 7.0 9 0 1 2 Tangential\n", $baselength/2+4 ;
printf OUT "%lf 7.0 9 0 1 2 Radial\n",$baselength+5 ;
printf OUT "%lf 7.0 9 0 1 2 Vertical\n",$baselength*3/2+6.0 ;
if($lflag==1){
    printf OUT "%lf 7.0 9 0 1 2 Tangential\n", $baselength/2+13 ;
    printf OUT "%lf 7.0 9 0 1 2 Radial\n",$baselength+14 ;
    printf OUT "%lf 7.0 9 0 1 2 Vertical\n",$baselength*3/2+15.0 ;
}
printf OUT "0.5 2.0 10 0 1 0 Var.Red: %1.1lf\%\n",$vr ;
printf OUT "0.5 2.3 10 0 1 0 CLVD   : %1.1lf\%\n",$clvd ;
printf OUT "0.5 2.6 10 0 1 0 Strike : %1.1lf deg.\n",$mstr ; 
printf OUT "0.5 2.9 10 0 1 0 Dip     : %1.1lf deg.\n", $mdip ; 
printf OUT "0.5 3.2 10 0 1 0 Rake   : %1.1lf deg.\n", $mrak ;

printf OUT "4.5 2.0 10 0 1 0 Toal %1.3e Nm\n",$tmom ;
printf OUT "4.5 2.3 10 0 1 0 Mrr: %1.3e\n", $mrr ; 
printf OUT "4.5 2.6 10 0 1 0 Mtt: %1.3e\n", $mtt ; 
printf OUT "4.5 2.9 10 0 1 0 Mff: %1.3e\n", $mff ;
printf OUT "4.5 3.2 10 0 1 0 Mrt: %1.3e\n", $mrt ; 
printf OUT "4.5 3.5 10 0 1 0 Mrf: %1.3e\n", $mrf ; 
printf OUT "4.5 3.8 10 0 1 0 Mtf: %1.3e\n", $mtf ;
close(OUT) ;

## Source Time Fucntion 
open( OUT, "> inputdata_gmt3_0.tmp") ;
printf OUT "4 6.25\n" ;
printf OUT "4 6\n" ;
printf OUT "%lf 6\n",4+$baselength ;
printf OUT "%lf 6.25\n",4+$baselength ;
printf OUT ">\n"  ;
close(OUT) ;

open( OUT, "> inputdata_gmt3_1.tmp" ) ;
$lengf=$baselength/$dleng[0] ;
for($i=0,$maxsmom=0.0  ; $i<$mtnum ; $i++){
    if($maxsmom < $smom[$i]){
	$maxsmom=$smom[$i] ;
    }
}
print "MOMENT NUM ",$mtnum, "\n" ;
for($i=0 ; $i<$mtnum ; $i++){
    print $smom[$i], " ", $lengf, "\n" ; 
    printf OUT "%lf %lf\n", $i*$mtint*$lengf+4, -$smom[$i]/$maxsmom*2+6 ;	
}
close(OUT) ;
## Moment tensor
open( OUT, "> inputdata_gmt4.tmp" ) ;
#for($i=0; $i<$mtnum ; $i++){
#    printf OUT "%lf 1 0 %1.5e %1.5e %1.5e %1.5e %1.5e %1.5e 8 0 0\n",
#    $i+1, $smrr[$i], $smtt[$i], $smff[$i], $smrt[$i], $smrf[$i], $smtf[$i] ;
#}
printf OUT "2 5 0 %1.5e %1.5e %1.5e %1.5e %1.5e %1.5e 21 0 0\n",
    $mrr, $mtt, $mff, $mrt, $mrf, $mtf ;
close( OUT ) ;

### Depth variation #############################
if( -e "itr_res_inv.out.all" ){
    @line=split(/\_/,$inprmfile) ;
    $timelabel=$line[2] ;
    open(CMD,"minmax -C itr_res_inv.out.all|");
    $line=<CMD> ;
    chop($line) ;
    close(CMD) ;
    @lines=split(/\s+/,$line) ;
    $deprng1=$lines[3]-5 ;
    $deprng2=$lines[4]+5 ;
    $deprng3=$lines[16]-20 ;
    $deprng4=$lines[16]+5 ;
    open(IN,"itr_res_inv.out.all");
    open(OUT,">inputdata_gmt8.tmp") ;
    while(<IN>){
	chop($_) ;
	@line=split(/\s+/,$_) ;
	if($line[0]==$timelabel){
	    print OUT "$line[7] $line[1] 0 $line[2] $line[3] $line[4] 5 0 0\n" ;
	}
    }
    close(OUT) ;
    close(IN) ;
    open(OUT,">inputdata_gmt9.tmp"); 
    printf OUT "16.5 6.6 11 0 2 0 V.R.\n";
    printf OUT "14.0  4.0 11 90 2 0 Depth\n" ;
    close(OUT) ;
}


#################################################

###########################
open(OUT,">inputdata_gmt5.tmp") ;
print OUT "$lon $lat\n" ;
close(OUT);
## SET STATION POSITION FILE ####################
open(OUT,">inputdata_gmt6.tmp") ;
open(OUT2,">inputdata_gmt7.tmp") ;
for( $i=0 ; $i<=$#stcd ; $i++){
    if( $strm[$i] =~ /BH/ || $strm[$i] =~ /BL/ ){
	print OUT "$slon{$stcd[$i]} $slat{$stcd[$i]} $lvr[$i]\n" ;
    }else{
	print OUT2 "$slon{$stcd[$i]} $slat{$stcd[$i]} $lvr[$i]\n" ;
    }
}
@sort_lvr=sort{ $a <=> $b } @lvr ;
close(OUT) ;
close(OUT2) ;
#################################################
for( $pagen=0, $pagei=1 ; $pagen<$stnum ; $pagen+=$pagewave, $pagei++){
    $outps=sprintf( "plot_%02d.ps",$pagei) ;
    ##-B10i/8iwesn
    system ( "psbasemap -R0/19/0/28 -Jx1c/-1c -G255 -P -K -X1 -Y1  > $outps" ) ;
### SOURCE TIME FUNCTION ##
    system ("$gmtdir/psxy -R -Jx -M -O -P -K -W0.5p inputdata_gmt3_0.tmp >> $outps" ) ;
    system ("$gmtdir/psxy -R -Jx -M -O -P -K -W1p inputdata_gmt3_1.tmp >> $outps" ) ;
# Moment tesnor #
    #system ("$gmtdir/psmeca -R -Jx -Sm1.0 -CpenP0.03 -P -O -K -T -a0.1c/d -G110/110/110 inputdata_gmt4.tmp >> $outps" ) ; # commented out by AG
    system ("$gmtdir/psmeca -R -Jx -Sm1.0 -P -O -K -T -a0.1c/d -G110/110/110 inputdata_gmt4.tmp >> $outps" ) ; # added by AG
#### OBS and SYN ####
    system("$gmtdir/psxy -R -Jx -M -O -P -K -W1p inputdata_gmt_p$pagei.tmp >> $outps") ;
    system("$gmtdir/psxy -R -Jx -M -O -P -K -W1t2_2:0p/255/0/0 inputdata_gmt2_p$pagei.tmp >> $outps") ;
    system("$gmtdir/pstext -R -Jx -O -P -K -V  inputdata_gmts_p$pagei.tmp  >> $outps") ;
#### Parameter Label ##
    system("$gmtdir/pstext -R -Jx -O -P -K -V  inputdata_gmt2_1.tmp  >> $outps") ;
    system("$gmtdir/pstext -R -Jx -O -P -K -V  inputdata_gmt2_2.tmp  >> $outps") ;
    if( -e "itr_res_inv.out"){
	system("$gmtdir/pstext -R -Jx -O -P -K -V inputdata_gmt9.tmp>>$outps");
    }
#### Plot Map ######
    system("$gmtdir/psbasemap -R$mapropt -J$mapjopt -B$mapbopt -O -P -K -X9 -Y21.5 >> $outps ") ;
    system("$gmtdir/pscoast -R -J$mapjopt -C200/255/255 -S200/255/255 -D$coastf -G200/255/200 -W0.5p -O -P -K >>$outps") ;
    system("$gmtdir/psxy -R -J$mapjopt -Sa0.5 -G200/0/0 -O -P -K -W0.5p inputdata_gmt5.tmp>>$outps" ) ;
############ make cpt #####
    system"$gmtdir/makecpt -Chot -T$sort_lvr[0]/$sort_lvr[$#sort_lvr]/1 -Z > residual_cpt.tmp" ;
    system"$gmtdir/psscale -B10 -Cresidual_cpt.tmp -D2/0.5/3/0.2h -O -P -K >>$outps" ;
###########################
    system("$gmtdir/psxy -R -J$mapjopt -Sc0.15 -Cresidual_cpt.tmp  -O -P -K -W0.5p inputdata_gmt6.tmp >>$outps") ;
    unless( -e "itr_res_inv.out" ){
	system("$gmtdir/psxy -R -J$mapjopt -Ss0.15 -Cresidual_cpt.tmp -O -P -W0.5p inputdata_gmt7.tmp >>$outps") ;
    } else {
### plot Depth Var ####
	system("$gmtdir/psxy -R -J$mapjopt -Ss0.15 -Cresidual_cpt.tmp -O -P -K -W0.5p inputdata_gmt7.tmp >>$outps") ;
	system("$gmtdir/psbasemap -R$vrropt -JX3c/-4c -B$vrbopt -O -P -K -X6 -Y1 >>$outps");
	system("$gmtdir/psmeca -R -JX -Sa0.20 -O -P inputdata_gmt8.tmp>>$outps") ;
    }
}
#####################
open( OUT, ">result_tdmrf_inv.dat") ;
printf OUT "%s %s %s %1.1lf %04d%02d%02d%02d%02d%1.2lf %s ",
    $lon, $lat, $cdepth,(log($tmom)/log(10)-9.1)/1.5, $year, $month, $day, $hour, $min, $sec,$hypolabel ;
printf OUT "%s %s %s ",
    $mstr,$mdip, $mrak ;
printf OUT "%1.4e %1.4e %1.4e %1.4e %1.4e %1.4e ",
    $mrr,$mtt,$mff,$mrt,$mrf,$mtf ;
printf OUT "%1.2lf %d %d\n",$vr,$fnetstnum, $tiltstnum ;
close(OUT) ;
#close(WRITE) ;

#@line=<READ> ;
#open( OUT,">> $outps") ;
#for($j=0 ; $j<$#line ; $j++){
#    print OUT "$line[$i]"  ;
#}
#close(READ) ;
#close(OUT) ;








