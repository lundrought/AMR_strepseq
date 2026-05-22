#!/bin/bash
# submit_amrfinder_all_species.sh
# Run this once — generates and submits one SLURM array job per species

FASTA_DIR=/home/projects2/strepseq_rmarvig/atb_data/fastas_exact
OUT_BASE=/home/projects2/strepseq_rmarvig/atb_data/amrfinder_results
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
#SBATCH --job-name=amr_${sp:0:10}
#SBATCH --array=1-${n}
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --output=${LOGS}/amrfinder_${sp}_%a.log
#SBATCH --error=${LOGS}/amrfinder_${sp}_%a.err

# conda initialize
source /home/ctools/miniconda3/etc/profile.d/conda.sh
conda activate /home/projects2/strepseq_rmarvig/tools/conda_envs/amrfinder

# paths
GENOME_DIR=${sp_dir}
OUT_DIR=${OUT_BASE}/${sp}_results

mkdir -p \$OUT_DIR

# pick genome N
GENOME=\$(ls \$GENOME_DIR*.fa | sed -n "\${SLURM_ARRAY_TASK_ID}p")
SAMPLE=\$(basename \$GENOME .fa)

echo "Running AMRFinder on: \$SAMPLE (species: ${sp}, index: \${SLURM_ARRAY_TASK_ID})"

amrfinder \
    --nucleotide \$GENOME \
    --threads 4 \
    --output \$OUT_DIR/\${SAMPLE}_amrfinder.tsv
EOF

done
