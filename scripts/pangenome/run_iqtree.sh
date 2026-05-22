#!/bin/bash
#SBATCH --job-name=iqtree_strep
#SBATCH --cpus-per-task=9
#SBATCH --mem=16G
#SBATCH --time=4:00:00
#SBATCH --output=logs/iqtree.log
#SBATCH --error=logs/iqtree.err

set -euo pipefail

# micromamba
export MAMBA_EXE=/home/projects2/strepseq_rmarvig/tools/bin/micromamba
export MAMBA_ROOT_PREFIX=/home/projects2/strepseq_rmarvig/tools/mamba
eval "$($MAMBA_EXE shell hook --shell bash)"
micromamba activate /home/projects2/strepseq_rmarvig/tools/conda_envs/iqtree

# paths
IN_FILE=/home/projects2/strepseq_rmarvig/results/panaroo_results/core_gene_alignment.aln
OUT_DIR=/home/projects2/strepseq_rmarvig/results/iqtree_results

mkdir -p "$OUT_DIR"
mkdir -p logs

# run iqtree
iqtree \
    -s "$IN_FILE" \
    -m GTR+G \
    -T 9 \
    -B 1000 \
    -pre "$OUT_DIR/strep_core_tree"

echo ""
echo "Done. Output in $OUT_DIR"
