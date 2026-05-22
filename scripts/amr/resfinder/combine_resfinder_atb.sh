#!/bin/bash
# combine_resfinder_atb.sh
# For each species subdirectory produced by submit_resfinder_atb.sh,
# concatenate ResFinder_results_tab.txt files into one TSV per species,
# then merge all species into a single master TSV.
#
# Expected input layout:
#   $INPUT_DIR/<species>_results_atb/<genome>/ResFinder_results_tab.txt
#
# Output:
#   $CLEAN_DIR/resfinder_<species>.tsv   (one per species)
#   $OUTPUT_DIR/combined_resfinder_atb_all.tsv  (master)
#
# Usage: bash combine_resfinder_atb.sh

set -euo pipefail

INPUT_DIR=${1:-/home/projects2/strepseq_rmarvig/atb_data/resfinder_results}
CLEAN_DIR=${2:-/home/projects2/strepseq_rmarvig/atb_data/resfinder_species_tables_clean}
OUTPUT_DIR=${3:-/home/projects2/strepseq_rmarvig/results/atb_results/resfinder_atb}

mkdir -p "$CLEAN_DIR" "$OUTPUT_DIR"

echo "Input dir  : $INPUT_DIR"
echo "Per-species: $CLEAN_DIR"
echo "Master out : $OUTPUT_DIR"
echo ""

MASTER=$OUTPUT_DIR/combined_resfinder_atb_all.tsv
> "$MASTER"   # truncate / create

HEADER_WRITTEN=0
SPECIES_COUNT=0

for sp_dir in "$INPUT_DIR"/*_results_atb/; do
    [ -d "$sp_dir" ] || continue

    species=$(basename "$sp_dir" | sed 's/_results_atb//')
    outfile="$CLEAN_DIR/resfinder_${species}.tsv"

    echo "Processing $species..."

    first=1
    genome_count=0

    for genome_dir in "$sp_dir"*/; do
        [ -d "$genome_dir" ] || continue
        genome=$(basename "$genome_dir")
        file="$genome_dir/ResFinder_results_tab.txt"

        [ -f "$file" ] || { echo "  WARNING: missing $file" >&2; continue; }

        if [ $first -eq 1 ]; then
            # Write header with Genome + Species prefix
            awk -v g="$genome" -v s="$species" \
                'BEGIN{OFS="\t"} NR==1{print "Genome","Species",$0} NR>1{print g,s,$0}' \
                "$file" > "$outfile"
            first=0
        else
            awk -v g="$genome" -v s="$species" \
                'BEGIN{OFS="\t"} NR>1{print g,s,$0}' \
                "$file" >> "$outfile"
        fi
        ((genome_count++))
    done

    echo "  $genome_count genomes"

    # Append to master (header only once)
    if [ -f "$outfile" ]; then
        if [ $HEADER_WRITTEN -eq 0 ]; then
            cat "$outfile" >> "$MASTER"
            HEADER_WRITTEN=1
        else
            tail -n +2 "$outfile" >> "$MASTER"
        fi
        ((SPECIES_COUNT++))
    fi
done

echo ""
echo "Done: $SPECIES_COUNT species combined"
echo "  Per-species TSVs : $CLEAN_DIR"
echo "  Master TSV       : $MASTER"
