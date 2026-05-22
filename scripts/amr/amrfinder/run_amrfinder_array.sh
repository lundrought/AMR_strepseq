#!/bin/bash
#SBATCH --job-name=amrfinder_strep
#SBATCH --array=1-96
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=logs/amrfinder_%a.log
#SBATCH --error=logs/amrfinder_%a.err

# conda initialize
source /home/ctools/miniconda3/etc/profile.d/conda.sh
conda activate /home/projects2/strepseq_rmarvig/tools/conda_envs/amrfinder

# paths
GENOME_DIR=/home/projects2/strepseq_rmarvig/assemblies
OUT_DIR=/home/projects2/strepseq_rmarvig/results/amrfinder_default

# genome N
GENOME=$(ls $GENOME_DIR/*.fna | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE=$(basename $GENOME .fna)

echo "Running AMRFinder on: $SAMPLE (job index: $SLURM_ARRAY_TASK_ID)"

mkdir -p $OUT_DIR
mkdir -p $OUT_DIR/logs

# run AMRFinder
amrfinder \
    --nucleotide $GENOME \
    --threads 4 \
    --output $OUT_DIR/${SAMPLE}_amrfinder.tsv
