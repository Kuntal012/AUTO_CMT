#!/usr/bin/perl
$key=$ARGV[0] ;
@lines=<STDIN> ;

for($i=0 ;$i<=$#lines ; $i++){
    $line=$lines[$i] ;
    chop($line) ;
    @data=split(/$key/,$line) ;
    print $data[0]."\n" ;
}
