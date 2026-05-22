#!/bin/bash
# subsample_fastas.sh — randomly select up to 50 genomes per species

FASTA_DIR=/home/projects2/strepseq_rmarvig/atb_data/fastas
SAMPLE_DIR=/home/projects2/strepseq_rmarvig/atb_data/fastas_50
MAX=50

mkdir -p "$SAMPLE_DIR"

for sp_dir in "$FASTA_DIR"/*/; do
    sp=$(basename "$sp_dir")
    all_fa=("$sp_dir"*.fa)
    n=${#all_fa[@]}

    mkdir -p "$SAMPLE_DIR/$sp"

    if [ "$n" -le "$MAX" ]; then
        # Fewer than 50 — use all
        cp "$sp_dir"*.fa "$SAMPLE_DIR/$sp/"
        echo "$sp : using all $n genomes"
    else
        # Randomly sample 50
        printf '%s\n' "${all_fa[@]}" | shuf -n "$MAX" | \
            xargs -I{} cp {} "$SAMPLE_DIR/$sp/"
        echo "$sp : sampled $MAX of $n genomes"
    fi
done

echo ""
echo "=== Final counts ==="
for sp_dir in "$SAMPLE_DIR"/*/; do
    sp=$(basename "$sp_dir")
    count=$(ls "$sp_dir"*.fa 2>/dev/null | wc -l)
    echo "  $sp : $count genomes"
done
