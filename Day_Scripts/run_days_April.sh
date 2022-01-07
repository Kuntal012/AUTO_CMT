for i in `seq 1 30`
do
	day=`more PF_CMT.m | grep "date_start" | head -n +1 | awk -F '=' '{print $2}'`
	echo "sed 's/date_start=${day}/date_start=${i}/' PF_CMT.m  > PF_April${i}.m"|sh 
	echo "sed 's/CMT/April${i}/g' cls_AD.sh > cls_April${i}.sh"|sh	  
	echo "sbatch cls_April${i}.sh"| sh
done
