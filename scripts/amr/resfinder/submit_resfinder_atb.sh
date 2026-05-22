#!/bin/bash
# submit_resfinder_atb.sh
# Run this once — it generates and submits one SLURM array job per species

FASTA_DIR=/home/projects2/strepseq_rmarvig/atb_data/fastas_exact
OUT_BASE=/home/projects2/strepseq_rmarvig/atb_data/resfinder_results
RESFINDER=/home/projects2/strepseq_rmarvig/tools/resfinder2
LOGS=/home/projects2/strepseq_rmarvig/atb_data/logs

mkdir -p "$LOGS"

for sp_dir in "$FASTA_DIR"/*/; do
    sp=$(basename "$sp_dir")
    n=$(ls "$sp_dir"*.fa 2>/dev/null | wc -l)

    if [ "$n" -eq 0 ]; then
        echo "Skipping $sp — no .fa files found"
        continue
    fi

    echo "Submitting $sp ($n genomes)"

    sbatch <<EOF
#!/bin/bash
#SBATCH --job-name=rf_${sp:0:10}
#SBATCH --array=1-${n}
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=${LOGS}/resfinder_${sp}_%a.log
#SBATCH --error=${LOGS}/resfinder_${sp}_%a.err

# conda initialize
source /home/ctools/miniconda3/etc/profile.d/conda.sh
conda activate /home/projects2/strepseq_rmarvig/tools/conda_envs/resfinder2

# paths
GENOME_DIR=${sp_dir}
OUT_DIR=${OUT_BASE}/${sp}_results_atb

# pick genome N
GENOME=\$(ls \${GENOME_DIR}*.fa | sed -n "\${SLURM_ARRAY_TASK_ID}p")
SAMPLE=\$(basename \$GENOME .fa)

echo "Running: \$SAMPLE (species: ${sp}, index: \${SLURM_ARRAY_TASK_ID})"
mkdir -p \$OUT_DIR/\$SAMPLE

python3 -m resfinder \
    -ifa \$GENOME \
    -o \$OUT_DIR/\$SAMPLE \
    -s "other" \
    -db_res ${RESFINDER}/resfinder_db \
    -db_point ${RESFINDER}/pointfinder_db \
    --acquired \
    --point
EOF

done
