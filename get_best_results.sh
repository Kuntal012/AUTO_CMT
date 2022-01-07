rm PF04_dir.txt PF04_results.txt

for l1 in `ls -d Output/*04`
do
	cd $l1
	for l2 in `ls -d 2004*`
	do
		cd $l2
		for l3 in `ls -d [0-2][0-9]/`
		do
			cd $l3
			pwd
			if [ -s Final_result.txt ]
			then
				l=`pwd| awk -F '/' '{print $9}'`
				echo $l >>/rhome/kchau012/bigdata/Parkfield_VLFE/CMT/PF04_dir.txt
				more Final_result.txt >> /rhome/kchau012/bigdata/Parkfield_VLFE/CMT/PF04_results.txt

			fi
			cd ../
		done
		cd ../
	done
	cd ../../
done

