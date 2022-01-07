#!/opt/linux/centos/7.x/x86_64/pkgs/perl/5.20.2/bin/perl

$infile=$ARGV[0] ;

unless( -e $infile) {
    die ;
}
open(IN,$infile) ;

$i==0 ;
while(<IN>){
#    print $_ ;
    chop($_) ;
#    print $_ ;
    @data=split(/\./,$_) ;
    $stcd=$data[6] ;
    $cmp=$data[8] ;
#    print "$stcd\n" ;
#    print "$cmp\n" ;
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
