#!/bin/sh
#SBATCH -J FilterMutect2
#SBATCH -o /fast/users/a1092098/launch/slurm-%j.out
#SBATCH -A robinson
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=00:30:00
#SBATCH --mem=1GB

# Notification configuration
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=clare.vaneyk@adelaide.edu.au

# load modules
module load Java/1.8.0_121
module load GATK
module load SAMtools

# run the executable
# A script to filter somatic variants called by gatk Mutect2, designed for the Phoenix supercomputer

usage()
{
echo "# A script to filter somatic variants called by gatk Mutect2, designed for the Phoenix supercomputer
# Requires: GATK and a list of samples
#
# Usage sbatch --array 0-(nSamples-1) $0  -v /path/to/vcf/files -S listofsamples.txt [-o /path/to/output] | [ - h | --help ]
#
# Options
# -S    REQUIRED. List of sample ID in a text file
# -v    REQUIRED. /path/to/vcf/files. Path to where you want to find your Mutect2 vcf files. Every file matching a sample ID will be used.
# -O    OPTIONAL. Path to where you want to find your file output (if not specified current directory is used)
# -h or --help  Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
#
#
# Original: Derived from GATK.HC.Phoenix by Mark Corbett, 16/11/2017
# Modified: (Date; Name; Description)
# 21/06/2018; Mark Corbett; Modify for Haloplex
# 09/07/2018; Clare van Eyk; modify for use with Mutect2 command from GATK
# 13/08/2019; Clare van Eyk; modify to filter Mutect2 calls with FilterMutectCalls
"
}

## Set Variables ##
while [ "$1" != "" ]; do
        case $1 in
                -S )                    shift
                                        SAMPLE=$1
                                        ;;
                -v )                    shift
                                        vcfDir=$1
                                        ;;
                -O )                    shift
                                        OutFolder=$1
                                        ;;
                -h | --help )           usage
                                        exit 0
                                        ;;
                * )                     usage
                                        exit 1
        esac
        shift
done

if [ -z "$SAMPLE" ]; then # If no SAMPLE name specified then do not proceed
        usage
        echo "#ERROR: You need to specify a list of sample ID in a text file eg.                                                                                                           /path/to/SAMPLEID.txt"
        exit 1
fi

# Define batch jobs based on samples
sampleID=($(cat $SAMPLE))

if [ -z "$vcfDir" ]; then # If no vcfDir name specified then do not proceed
        usage
        echo "#ERROR: You need to tell me where to find the vcf files."
        exit 1
fi
if [ -z "$OutFolder" ]; then # If no output directory then use default directory
        OutFolder=$FASTDIR/WGS/Mosaic/Filtered_Calls
        echo "Using $FASTDIR/WGS/Mosaic/Filtered_calls as the output directory"
fi
if [ ! -d $OutFolder ]; then
        mkdir -p $OutFolder
fi

tmpDir=$FASTDIR/tmp/${sampleID[$SLURM_ARRAY_TASK_ID]} # Use a tmp directory for all of the GATK and samtools temp files
if [ ! -d $tmpDir ]; then
        mkdir -p $tmpDir
fi

## Start of the script ##
###On each sample###
cd $tmpDir
gatk FilterMutectCalls \
-I $vcfDir/${sampleID[$SLURM_ARRAY_TASK_ID]}.mosaic.PONs_gnomad.vcf \
--max-germline-posterior 0.1 \
-O $OutFolder/${sampleID[$SLURM_ARRAY_TASK_ID]}.filtered.vcf >> $tmpDir/${sampleID[$SLURM_ARRAY_TASK_ID]}.filter.pipeline.log 2>&1
