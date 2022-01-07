#!/usr/bin/perl

$infile=$ARGV[0] ;

unless( -e $infile) {
    die ;
}
open(IN,$infile) ;

$i==0 ;
while(<IN>){
#    print $_ ;
    chop($_) ;
    @data=split(/\./,$_) ;
    $stcd=$data[7] ;
    $cmp=$data[9] ;
    if($stcd eq $bfst){
	print " $cmp" ;
    }elsif($i==0){
	print "$stcd $cmp" ;
    }else{
	print "\n$stcd $cmp" ;
    }
    $bfst=$stcd ;
    $i++ ;
}
close(IN) ;
print "\n" ;
