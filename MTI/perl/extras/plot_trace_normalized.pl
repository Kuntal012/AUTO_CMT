#!/usr/bin/perl

### PERL #####
use Cwd ;
use Time::Local ;
require "lib1.pl" ;
###############
$ENV{SACDIR}="/Users/yito/MyApplication/sac" ;
$ENV{SACAUX}="/Users/yito/MyApplication/sac/lib/aux" ;
#################
$cdir=getcwd() ;
print $cdir."\n" ;
#die ;
#### defaults ##############
@filter1=("2","8") ;
@filter2=("0.02","0.05") ;
$deconvf=0 ;
############################
for($i=0 ; $i<=$#ARGV ; $i++){
    if($ARGV[$i] =~ /^-H/){
	$ARGV[$i] =~ s/^-H// ;
	@filter1=split(/\//,$ARGV[$i]) ;
    }elsif($ARGV[$i] =~ /^-L/){
	$ARGV[$i] =~ s/^-L// ;
	@filter2=split(/\//,$ARGV[$i]) ;
    }elsif($ARGV[$i] =~ /^-D/){
	$deconvf=1 ;
    }else{
	$infile=$ARGV[$i] ;
    }
    
}

print "FILTER1 $filter1[0] $filter1[1]\n" ;
print "FILTER2 $filter2[0] $filter2[1]\n" ;

###die ;
##############################
##################################################
open(IN, $infile) ;
while(<IN>){
    chop($_) ;
    @data=split(/\s+/,$_) ;
    $wdir=$data[0] ;
    $filehead=$data[1] ;
    $wdir=$wdir ;
    ###########################
    splice(@stcds, 0,$#stcds+1) ;
    splice(@strms, 0,$#strms+1) ;
    for($i=2; $i<=$#data ; $i++){
	@data2=split(/\./,$data[$i]) ;
	if($data2[1] =~ /^BH/ || $data2[1] =~ /^HH/){
	    push(@stcds, $data2[0]) ;
	    push(@strms, $data2[1]) ;
	}
    }    
    for($i=0; $i<=$#stcds ; $i++){
	print "$stcds[$i]  $strms[$i]\n" ;
    }
    
    ### output ps name ######
    $psfile="plot_".$wdir.".ps" ;
    $pdfile="plot_".$wdir.".pdf" ;
    ### move working dir #####
    chdir($cdir) ;
    ### move event dir #######
    chdir($wdir) ;
    print "WORK DIR $wdir\n" ;
    ###################################################
    $vnm=$#stcds+2 ;
    $ropt="-R0\/60\/0\/$vnm" ;
    system "gmtset MEASURE_UNIT cm\n" ;
    system "gmtset PAPER_MEDIA A4\n" ;
    system "psbasemap $ropt -B10f1/100f100WsNe -JX24c/8c -K -X3 -Y11 > $psfile" ;
    system "psbasemap $ropt -B10f1/100f100WSne -JX24c/8c -O -K -Y-9 >>$psfile" ;
    #die ;
    ###################################################
    $YYYY=substr($wdir,0,4) ;
    $MM=substr($wdir,4,2) ;
    $DD=substr($wdir,6,2) ;
    $hh=substr($wdir,8,2) ;
    $mm=substr($wdir,10,2) ;
    
    for($i=0 ; $i<=$#stcds ; $i++){
	$stcd=$stcds[$i] ;
	$strm=$strms[$i] ;
	$wavefile=$filehead.".CN.".$stcd."..".$strm.".D.SAC" ;
	
	open(CMD,"ls SAC\_PZs\_CN\_$stcd\_$strm\_\*|") ;
	$line=<CMD> ;
	close(CMD) ;
	print "POLEZERO FILE list $line" ;
	chop($line) ;
	$respf=$line ;
	
	if( -e $wavefile ){
	    print "Found $wavefile -->  ";
	}else{
	    print "Not Found $wavefile -->  " ;
	}
	if( -e $respf ){
	    print "Found $respf\n" ;
	}else{
	    print "Not Found $respfq\n" ;
	}
     ### read sac file ###
	################################
	### read Constant Polezero file#
	################################
	#open(RIN,$respf) ;
	#while(<RIN>){
	#    if($_ =~ /^CONSTANT/){
	#	chop($_); 
	#	@data=split(/\s+/,$_) ;
	#	$sen=$data[1] ;
	#    }
	#}
	#close(RIN) ;
	#print "constant $sen\n" ;
	#################################
	###############
	open(SAC, "|sac\n") ;
	print SAC "r $wavefile\n" ;
	#print SAC "div $sen\n" ;
	print SAC "rmean\n" ;
	print SAC "rtr\n" ;
	if($deconvf==1){
	    print SAC "transfer from polezero s $respf\n" ;
	}
	print SAC "bp co $filter1[0] $filter1[1] p 2\n" ;
	print SAC "rmean\n" ;
	print SAC "interpolate delta 0.1\n" ;
	print SAC "w alpha high.ascii\n " ;
	#print SAC "w alpha high.ascii.$i\n " ;
	##########
	print SAC "r $wavefile\n" ;
	print SAC "rmean\n" ;
	print SAC "rtr\n" ;
	if($deconvf==1){
	    print SAC "transfer from polezero s $respf\n" ;
	}
#print SAC "div $sen\n" ;
	print SAC "bp co $filter2[0] $filter2[1] p 2\n" ;
	print SAC "rmean\n" ;
	print SAC "interpolate delta 1\n" ;
	print SAC "w alpha low.ascii\n " ;
	#print SAC "w alpha low.ascii.$i\n " ;
	print SAC "quit\n" ;
	close(SAC) ;
	
        ### read ASCII FILE ###
	$ret=mylib::read_sac_alpha("high.ascii", *headerh,  *waveh) ;
	$ret=mylib::read_sac_alpha("low.ascii",  *headerl, *wavel) ;
	##########################################
	## rmean again ###########################
	### higher part ;
	
	for($j=0,$rmean=0,$dn=0 ; $j<=$#waveh ; $j++){
	    if($j*$headerh[0]/60 > 2 && $j*$headerh[0]/60 < 60){
		$rmean+=$waveh[$j] ;
		$dn++ ;
	    }
	}
	$rmean/=$dn ;
	for($j=0,$maxh=0 ; $j<=$#waveh ; $j++){
	    $waveh[$j]-=$rmean ;
	    if($j*$headerh[0]/60 > 2 && $j*$headerh[0]/60 < 60){
		if(abs($waveh[$j])>$maxh){
		    $maxh=$waveh[$j] ;
		}
	    }
	}
	####
	### lower part ;
	for($j=0,$rmean=0,$dn=0 ; $j<=$#wavel ; $j++){
	    if($j*$headerl[0]/60 > 2 && $j*$headerl[0]/60 < 60){
		$rmean+=$wavel[$j] ;
		$dn++ ;
	    }
	}
	$rmean/=$dn ;
	for($j=0, $maxl=0 ; $j<=$#wavel ; $j++){
	    $wavel[$j]-=$rmean ;
	    if($j*$headerl[0]/60 > 2 && $j*$headerl[0]/60 < 60){
		if(abs($wavel[$j])>$maxl){
		    $maxpoint =$j*$headerl[0]/60 ;
		    $maxl=$wavel[$j] ;
		}
	    }
	}
	#####
	$maxh*=2 ;
	$maxl*=2 ;
	print "$maxpoint  $maxl\n" ;
	##########################################

        ### plot GMT #####
	open(OUT, ">test$i.tmp") ;
	open(CMD, "|psxy -R -JX -O -K -Y9 -W0.5p >>$psfile") ;
	for($j=0; $j<=$#waveh ; $j++){
	    printf CMD  "%lf %1.5e\n", $j*$headerh[0]/60,$waveh[$j]/$maxh+$i+1 ;
	    printf OUT  "%lf %1.5e\n", $j*$headerh[0]/60,$waveh[$j]/$maxh+$i+1 ;
	}
	close(CMD) ;
	close(OUT) ;
	
	open(CMD, "|psxy -R -JX -O -K -Y-9 -W0.5p >>$psfile") ;
	for($j=0; $j<=$#wavel ; $j++){
	    printf CMD "%lf %1.5e\n", $j*$headerl[0]/60,$wavel[$j]/$maxl+$i+1 ;
	    printf OUT "%lf %1.5e\n", $j*$headerl[0]/60,$wavel[$j]/$maxl+$i+1 ;
	}
	close(CMD) ;
    }
    ### Title & station code #####
    open(CMD, "|pstext -R -JX -O -N -K -Y9>>$psfile") ;
    for($i=0; $i<=$#stcds ; $i++){
	$pos=$i+1 ;
	print CMD "-0.2 $pos 12 0 4 RM $stcds[$i]\n" ;
    }
    close(CMD) ;
    
    
    open(CMD, "|pstext -R -JX -O -K -N -Y-9 >>$psfile") ;
    for($i=0; $i<=$#stcds ; $i++){
	$pos=$i+1 ;
	print CMD "-0.2 $pos 12 0 4 RM $stcds[$i]\n" ;
    }
    close(CMD) ;
    ##################
    $ropt="-R0/60/0/12" ;
    open(CMD, "|pstext $ropt -JX24/1 -O -P  -Y-1.5 >> $psfile") ;
    $datetitle=$YYYY."\/".$MM."\/".$DD." ".$hh ;
    print CMD "0 0 20 0 4 LB $datetitle\n" ;
    print CMD "13 0 20 0 4 LB Top: $filter1[0] - $filter1[1] Hz    Bottom: $filter2[0] - $filter2[1] Hz\n" ;  
    printf CMD "42 0 20 0 4 LB Amp: Norm./Norm.\n",$highm, $lowm ;
    close(CMD) ;
    
    system "convert $psfile $pdfile" ;
    #die ;
}
close(IN) ;
