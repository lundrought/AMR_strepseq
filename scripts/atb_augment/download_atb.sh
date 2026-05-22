#!/bin/bash
# download_atb.sh
# Download Streptococcus genomes from AllTheBacteria for the species
# identified in our dataset (GTDB r214 names).
#
# Steps:
#   1. Download the ATB file manifest
#   2. Filter to target species and write strep_files.tsv + URL list
#   3. Download unique .tar.xz archives
#   4. Extract only the target genomes into fastas/<species>/
#
# Usage: bash download_atb.sh [workdir]
# Default workdir: /home/projects2/strepseq_rmarvig/atb_data

set -euo pipefail

WORKDIR=${1:-/home/projects2/strepseq_rmarvig/atb_data}
FILELIST=$WORKDIR/file_list.all.latest.tsv.gz
OUTPUT_TSV=$WORKDIR/strep_files.tsv
URL_LIST=$WORKDIR/strep_urls.txt
FASTA_DIR=$WORKDIR/fastas_exact
TMP_EXTRACT=$WORKDIR/tmp_extract

mkdir -p "$WORKDIR" "$FASTA_DIR" "$TMP_EXTRACT"

# 1. Download manifest
if [ ! -f "$FILELIST" ]; then
    echo "Downloading ATB manifest..."
    wget -q --show-progress \
        -O "$FILELIST" \
        https://osf.io/download/69a040c86a4dd653508ac769/
else
    echo "Manifest already present, skipping download."
fi

#  2. Filter to target species
echo ""
echo "Filtering to target species"


# GTDB r214 species names found in our dataset
SPECIES=(
    "gordonii"
    "salivarius"
    "sp902460355"
    "anginosus_C"
    "anginosus"
    "sp001556435"
    "sanguinis"
    "oralis"
    "ilei"
    "sanguinis_G"
    "cristatus"
    "xiaochunlingii"
    "sp001808705"
    "parasanguinis_I"
    "oralis_I"
    "sanguinis_H"
    "mitis_AZ"
    "sp900766505"
    "sp001553685"
    "parasanguinis_B"
    "infantis_F"
    "parasanguinis"
    "parasanguinis_D"
    "parasanguinis_C"
    "vestibularis"
    "sp001813295"
    "oralis_K"
    "oralis_T"
    "parasanguinis_E"
    "constellatus"
    "sp900555155"
)

> "$OUTPUT_TSV"
for sp in "${SPECIES[@]}"; do
    echo "  Collecting: Streptococcus $sp"
    zcat "$FILELIST" | awk -F'\t' -v sp="$sp" '$2 == ("Streptococcus " sp)' >> "$OUTPUT_TSV"
done

echo ""
echo "Genomes per species:"
cut -f2 "$OUTPUT_TSV" | sed 's/^Streptococcus //' | sort | uniq -c | sort -rn
echo ""
TOTAL=$(wc -l < "$OUTPUT_TSV")
echo "Total genomes: $TOTAL"

# Unique archive URLs
cut -f5 "$OUTPUT_TSV" | sort -u > "$URL_LIST"
echo "Unique archives: $(wc -l < "$URL_LIST")"

# 3. Download archives 
echo ""
echo "Downloading archives"


cd "$WORKDIR"
while read -r url; do
    fname=$(basename "$url")
    if [ ! -f "$fname" ]; then
        echo "  Downloading: $fname"
        curl -L --retry 3 --retry-delay 5 -o "$fname" "$url"
    else
        echo "  Already exists, skipping: $fname"
    fi
done < "$URL_LIST"

#  4. Extract target genomes
echo ""
echo "Extracting genomes"


while read -r url; do
    archive=$(basename "$url")
    echo ""
    echo "Processing archive: $archive"

    awk -F'\t' -v u="$url" '$5 == u' "$OUTPUT_TSV" | \
    while IFS=$'\t' read -r sample species filepath tarfile url md5 size; do
        sp_exact="${species#Streptococcus }"
        sp_dir="$FASTA_DIR/$sp_exact"
        mkdir -p "$sp_dir"
        dest="$sp_dir/${sample}.fa"

        if [ ! -f "$dest" ]; then
            tar -xJf "$WORKDIR/$archive" -C "$TMP_EXTRACT" "$filepath" 2>/dev/null || true
            extracted="$TMP_EXTRACT/$filepath"

            if [ -f "$extracted" ]; then
                mv "$extracted" "$dest"
                echo "  OK: $sample → $sp_exact/"
            else
                echo "  FAILED: $sample (not found in archive)" >&2
            fi
        fi
    done
done < "$URL_LIST"

rm -rf "$TMP_EXTRACT"

# 5. Summary 
echo ""
echo "Dataset summary"

GRAND_TOTAL=0
for dir in "$FASTA_DIR"/*/; do
    sp=$(basename "$dir")
    count=$(ls "$dir"*.fa 2>/dev/null | wc -l)
    echo "  $sp : $count genomes"
    GRAND_TOTAL=$((GRAND_TOTAL + count))
done
echo ""
echo "Total genomes extracted: $GRAND_TOTAL"
echo "Done!"
