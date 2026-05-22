#!/bin/bash
#SBATCH --job-name=resfinder_strep
#SBATCH --array=1-96
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=logs/resfinder_%a.log
#SBATCH --error=logs/resfinder_%a.err

#conda initialize
source /home/ctools/miniconda3/etc/profile.d/conda.sh
conda activate /home/projects2/strepseq_rmarvig/tools/conda_envs/resfinder2


# paths 
GENOME_DIR=/home/projects2/strepseq_rmarvig/assemblies
OUT_DIR=/home/projects2/strepseq_rmarvig/results/resfinde_default
RESFINDER=/home/projects2/strepseq_rmarvig/tools/resfinder2

# genome N
GENOME=$(ls $GENOME_DIR/*.fna | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE=$(basename $GENOME .fna)

echo "Running sample: $SAMPLE (job index: $SLURM_ARRAY_TASK_ID)"

# make output folder for this sample 
mkdir -p $OUT_DIR/$SAMPLE

# run ResFinder 
python3 -m resfinder \
    -ifa $GENOME \
    -o $OUT_DIR/$SAMPLE \
    -s "other" \
    -db_res $RESFINDER/resfinder_db \
    -db_point $RESFINDER/pointfinder_db \
    --acquired \
    --point 
