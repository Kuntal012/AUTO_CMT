for i in `seq 14 16`
do
	day=`more AD_Parallel.m | grep "date_start" | head -n +1 | awk -F '=' '{print $2}'`
	echo "sed -i 's/date_start=${day}/date_start=${i}/' AD_Parallel.m" 
	echo "sed -i 's/date_start=${day}/date_start=${i}/' AD_Parallel.m"  | sh
	sbatch cls_AD.sh 
done
