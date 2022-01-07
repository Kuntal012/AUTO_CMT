#!/bin/bash -l

#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=1-00:15:00     # 1 day and 15 minutes
#SBATCH --output=AD_LandS.o
#SBATCH --mail-user=kchau012@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="AD_LandS"
#SBATCH -p batch # This is the default partition, you can use any of the following; intel, batch, highmem, gpu


# Print current date
date

echo 'Autodetect_LS;quit'|matlab -nodesktop



