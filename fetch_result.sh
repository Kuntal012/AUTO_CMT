day=`more inputdata_gmt2_1.tmp| head -n 1 | awk '{print $7}'| awk -F '/' '{print $1" "$2" "$3}'` 
  tim=`more inputdata_gmt2_1.tmp| head -n 1 | awk '{print $8}'| awk -F ':' '{print $1" "$2" "$3}'`
  lon=`more inputdata_gmt2_1.tmp| tail -n +2 | awk '{print $7}'`
  lat=`more inputdata_gmt2_1.tmp| tail -n +2 | awk '{print $8}'`
  dep=`more inputdata_gmt2_1.tmp| tail -n +2 | awk '{print $9}'`
  mag=`more inputdata_gmt2_1.tmp| tail -n +2 | awk '{print $11}'`
  var=`more inputdata_gmt2_2.tmp| head -n +5|tail -n +5| awk '{print substr($8,1,length($8)-1)}'`
  clvd=`more inputdata_gmt2_2.tmp| head -n +6|tail -n +6| awk '{print substr($9,1,length($9)-1)}'`
  #strike=`more inputdata_gmt2_2.tmp| head -n +7|tail -n +7| awk '{print $9}'`
  s1=`more inputdata_gmt7.tmp| head -n 1| awk '{print $3}'`
  s2=`more inputdata_gmt7.tmp| head -n 2| tail -n +2| awk '{print $3}'`
  s3=`more inputdata_gmt7.tmp| head -n 3| tail -n +3| awk '{print $3}'`
  	# For a Fourth station
  	s4=`more inputdata_gmt7.tmp| head -n 4| tail -n +4 |awk '{print $3}'`
  
  s1_c=`echo $s1'>0' | bc -l`
  s2_c=`echo $s2'>0' | bc -l`
  s3_c=`echo $s3'>0' | bc -l`
  s4_c=`echo $s4'>0' | bc -l`
  #rm Final_result.txt
  #echo "$pp  $i  $day  $tim  $lon  $lat  $dep  $mag  $var  $clvd $s1 $s2 $s3" 
  if [[ $s1_c -eq 1 && ${s2_c} -eq 1 && ${s3_c} -eq 1 && ${s4_c} -eq 1]]
  then
  	echo "$day  $tim  $lon  $lat  $dep  $mag  $var  $clvd $s1 $s2 $s3 $s4" > ./Result.txt
  fi

