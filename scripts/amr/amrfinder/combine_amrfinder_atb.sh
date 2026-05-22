#!/bin/bash
# combine_amrfinder_atb.sh
# For each species subdirectory produced by submit_amrfinder_atb.sh,
# concatenate *_amrfinder.tsv files into one TSV per species,
# then merge all species into a single master TSV.
#
# Expected input layout:
#   $INPUT_DIR/<species>_results/<genome>_amrfinder.tsv
#
# Output:
#   $CLEAN_DIR/amrfinder_<species>.tsv   (one per species)
#   $OUTPUT_DIR/combined_amrfinder_atb_all.tsv  (master)
#
# Usage: bash combine_amrfinder_atb.sh

set -euo pipefail

INPUT_DIR=${1:-/home/projects2/strepseq_rmarvig/atb_data/amrfinder_results}
CLEAN_DIR=${2:-/home/projects2/strepseq_rmarvig/atb_data/amrfinder_species_tables_clean}
OUTPUT_DIR=${3:-/home/projects2/strepseq_rmarvig/results/atb_results/amrfinder_atb}

mkdir -p "$CLEAN_DIR" "$OUTPUT_DIR"

echo "Input dir  : $INPUT_DIR"
echo "Per-species: $CLEAN_DIR"
echo "Master out : $OUTPUT_DIR"
echo ""

MASTER=$OUTPUT_DIR/combined_amrfinder_atb_all.tsv
> "$MASTER"

HEADER_WRITTEN=0
SPECIES_COUNT=0

for sp_dir in "$INPUT_DIR"/*_results/; do
    [ -d "$sp_dir" ] || continue

    species=$(basename "$sp_dir" | sed 's/_results//')
    outfile="$CLEAN_DIR/amrfinder_${species}.tsv"

    echo "Processing $species..."

    first=1
    genome_count=0

    for file in "$sp_dir"*_amrfinder.tsv; do
        [ -f "$file" ] || continue
        genome=$(basename "$file" _amrfinder.tsv)

        if [ $first -eq 1 ]; then
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
