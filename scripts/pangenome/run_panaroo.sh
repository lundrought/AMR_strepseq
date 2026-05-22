#!/bin/bash

#SBATCH --job-name=panaroo_strep
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=logs/panaroo.log
#SBATCH --error=logs/panaroo.err

set -euo pipefail
 
# micromamba
export MAMBA_EXE=/home/projects2/strepseq_rmarvig/tools/bin/micromamba
export MAMBA_ROOT_PREFIX=/home/projects2/strepseq_rmarvig/tools/mamba
eval "$($MAMBA_EXE shell hook --shell bash)"
micromamba activate /home/projects2/strepseq_rmarvig/tools/conda_envs/panaroo
 
# paths 
BAKTA_DIR=/home/projects2/strepseq_rmarvig/results/bakta_results
OUT_DIR=/home/projects2/strepseq_rmarvig/results/panaroo_results
 
mkdir -p "$OUT_DIR"
mkdir -p logs


# collect .gff files
GFF_FILES=$(find "$BAKTA_DIR" -name "*.gff" | sort)
N_GFF=$(echo "$GFF_FILES" | wc -l)
 
echo "Found $N_GFF .gff files"
 
if [ "$N_GFF" -ne 89 ]; then
    echo "ERROR: expected 89 .gff files, found $N_GFF"
    echo "       Check Bakta output and .gff symlinks before proceeding."
    exit 1
fi
 


# run Panaroo
panaroo \
    --input $GFF_FILES \
    --out_dir "$OUT_DIR" \
    --clean-mode strict \
    --alignment core \
    --aligner mafft \
    --core_threshold 0.98 \
    --len_dif_percent 0.98 \
    --threads 16



# check output
echo ""
echo "Panaroo output"
ls -lh "$OUT_DIR"
 
if [ -f "$OUT_DIR/core_gene_alignment.aln" ]; then
    echo ""
    echo "Core gene alignment produced — ready for tree building."
    NGENES=$(grep -c "^>" "$OUT_DIR/core_gene_alignment.aln" || true)
    echo "Sequences in alignment: $NGENES (should be 89)"
else
    echo "WARNING: core_gene_alignment.aln not found — check logs/panaroo.err"
    exit 1
fi
 
if [ -f "$OUT_DIR/summary_statistics.txt" ]; then
    echo ""
    echo "Pan-genome summary"
    cat "$OUT_DIR/summary_statistics.txt"
fi
