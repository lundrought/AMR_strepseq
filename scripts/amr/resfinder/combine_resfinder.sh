#!/bin/bash
# combine_resfinder.sh
# Concatenate per-sample ResFinder_results_tab.txt and pheno_table.txt
# into two combined TSVs for the 96 own-sample runs.
#
# Usage: bash combine_resfinder.sh
# Run from: results/resfinder_default/

set -euo pipefail

INPUT_DIR=${1:-/home/projects2/strepseq_rmarvig/results/resfinder_default}
OUTPUT_DIR=${2:-/home/projects2/strepseq_rmarvig/results}

GENE_OUT=$OUTPUT_DIR/combined_resfinder_default.tsv
PHENO_OUT=$OUTPUT_DIR/combined_pheno_def.tsv

echo "Input dir : $INPUT_DIR"
echo "Gene out  : $GENE_OUT"
echo "Pheno out : $PHENO_OUT"
echo ""

# Gene table 
echo "Building gene table..."

# Header from first sample that has a results file
FIRST_FILE=$(find "$INPUT_DIR" -name "ResFinder_results_tab.txt" | head -1)
if [ -z "$FIRST_FILE" ]; then
    echo "ERROR: no ResFinder_results_tab.txt found under $INPUT_DIR" >&2
    exit 1
fi

head -1 "$FIRST_FILE" | awk '{print "Sample\t"$0}' > "$GENE_OUT"

FOUND=0
MISSING=0
for dir in "$INPUT_DIR"/*/; do
    SAMPLE=$(basename "$dir")
    FILE="$dir/ResFinder_results_tab.txt"
    if [ -f "$FILE" ]; then
        awk -v s="$SAMPLE" 'NR>1{print s"\t"$0}' "$FILE" >> "$GENE_OUT"
        ((FOUND++))
    else
        echo "  WARNING: missing $FILE" >&2
        ((MISSING++))
    fi
done

echo "  Gene table: $FOUND samples written, $MISSING missing"
echo ""

# Pheno table 
echo "Building pheno table..."

echo -e "Sample\tAntimicrobial\tClass\tWGS_phenotype\tMatch\tGenetic_background" > "$PHENO_OUT"

FOUND=0
MISSING=0
for dir in "$INPUT_DIR"/*/; do
    SAMPLE=$(basename "$dir")
    FILE="$dir/pheno_table.txt"
    if [ -f "$FILE" ]; then
        grep -v "^#" "$FILE" | grep -v "^$" | \
            awk -v s="$SAMPLE" '{print s"\t"$0}' >> "$PHENO_OUT"
        ((FOUND++))
    else
        echo "  WARNING: missing $FILE" >&2
        ((MISSING++))
    fi
done

echo "  Pheno table: $FOUND samples written, $MISSING missing"
echo ""
echo "Done."
echo "  $GENE_OUT"
echo "  $PHENO_OUT"
