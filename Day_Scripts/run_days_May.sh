for i in 2 4 8
do
	day=`more PF_CMT.m | grep "date_start" | head -n +1 | awk -F '=' '{print $2}'`
	echo "sed 's/date_start=${day}/date_start=${i}/' PF_CMT.m  > PF_May${i}.m"|sh 
	echo "sed 's/CMT/May${i}/g' cls_AD.sh > cls_May${i}.sh"|sh	  
	echo "sbatch cls_May${i}.sh"| sh
done
