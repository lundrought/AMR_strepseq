#!/bin/bash
# combine_amrfinder.sh
# Concatenate per-sample AMRFinder TSVs into one combined TSV
# for the 96 own-sample runs.
#
# Usage: bash combine_amrfinder.sh
# Run from anywhere; paths are absolute.

set -euo pipefail

INPUT_DIR=${1:-/home/projects2/strepseq_rmarvig/results/amrfinder_results}
OUTPUT_DIR=${2:-/home/projects2/strepseq_rmarvig/results}

OUT=$OUTPUT_DIR/combined_amrfinder_def.tsv

echo "Input dir : $INPUT_DIR"
echo "Output    : $OUT"
echo ""

# Header from the first file found
FIRST_FILE=$(find "$INPUT_DIR" -name "*_amrfinder.tsv" | head -1)
if [ -z "$FIRST_FILE" ]; then
    echo "ERROR: no *_amrfinder.tsv files found under $INPUT_DIR" >&2
    exit 1
fi

head -1 "$FIRST_FILE" | awk '{print "Sample\t"$0}' > "$OUT"

FOUND=0
MISSING=0
for f in "$INPUT_DIR"/*_amrfinder.tsv; do
    [ -f "$f" ] || { ((MISSING++)); continue; }
    SAMPLE=$(basename "$f" _amrfinder.tsv)
    tail -n +2 "$f" | awk -v s="$SAMPLE" '{print s"\t"$0}' >> "$OUT"
    ((FOUND++))
done

echo "  $FOUND files combined, $MISSING missing"

# The notebook strips a spurious "combined\t" prefix that can appear
# if this script is re-run on a partially combined file; guard against it here
# by ensuring the Sample column never equals the output filename stem.
STEM=$(basename "$OUT" .tsv)
if grep -q "^${STEM}" "$OUT" 2>/dev/null; then
    echo "  Fixing spurious prefix lines..."
    sed -i "s/^${STEM}\t//" "$OUT"
fi

echo ""
echo "Done: $OUT"
