#!/bin/bash

#SBATCH --job-name=bakta_strep
#SBATCH --array=2-89
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=logs/bakta_%a.log
#SBATCH --error=logs/bakta_%a.err

set -euo pipefail

export MAMBA_EXE=/home/projects2/strepseq_rmarvig/tools/bin/micromamba
export MAMBA_ROOT_PREFIX=/home/projects2/strepseq_rmarvig/tools/mamba
eval "$($MAMBA_EXE shell hook --shell bash)"
micromamba activate /home/projects2/strepseq_rmarvig/tools/conda_envs/bakta


# paths

GENOME_DIR=/home/projects2/strepseq_rmarvig/data/assemblies_89   # symlinked 89 .fna files
OUT_DIR=/home/projects2/strepseq_rmarvig/results/bakta_results
BAKTA_DB=/home/projects2/strepseq_rmarvig/tools/bakta_db/db # path to extracted db dir
 
mkdir -p "$OUT_DIR"
mkdir -p logs

# pick genome
GENOME=$(ls "$GENOME_DIR"/*.fna | sed -n "${SLURM_ARRAY_TASK_ID}p")
SAMPLE=$(basename "$GENOME" .fna)
 
echo "Running Bakta on: $SAMPLE  (job index: $SLURM_ARRAY_TASK_ID)"


# run bakta
bakta \
    --db "$BAKTA_DB" \
    --output "$OUT_DIR/$SAMPLE" \
    --prefix "$SAMPLE" \
    --genus Streptococcus \
    --gram + \
    --keep-contig-headers \
    --skip-plot \
    --skip-crispr \
    --threads 4 \
    --force \
    "$GENOME"


# check gff3 file

GFF3="$OUT_DIR/$SAMPLE/${SAMPLE}.gff3"
if [ -f "$GFF3" ]; then
    echo "OK: $GFF3"
else
    echo "ERROR: $GFF3 not produced for $SAMPLE"
    exit 1
fi



