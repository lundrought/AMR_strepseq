#!/bin/bash
# setup_symlinks.sh


# paths
ASSEMBLY_DIR=/home/projects2/strepseq_rmarvig/assemblies   # original .fna files
SYMLINK_DIR=/home/projects2/strepseq_rmarvig/assemblies_89 # output directory
KEEP_LIST=/home/projects2/strepseq_rmarvig/results/keep_samples.txt # one GM_FILE_ID per line

mkdir -p "$SYMLINK_DIR"


# create symlinks 
echo "Creating symlinks in $SYMLINK_DIR ..."
echo ""

FOUND=0
MISSING=0

while IFS= read -r sample_id || [[ -n "$sample_id" ]]; do
    # Skip blank lines and comments
    [[ -z "$sample_id" || "$sample_id" == \#* ]] && continue

    fna_file="$ASSEMBLY_DIR/${sample_id}.fna"

    if [ -f "$fna_file" ]; then
        ln -sf "$fna_file" "$SYMLINK_DIR/${sample_id}.fna"
        ((FOUND++))
    else
        echo "WARNING: .fna not found for $sample_id"
        ((MISSING++))
    fi

done < "$KEEP_LIST"

echo ""
echo "Done."
echo "  Symlinks created : $FOUND"
echo "  Missing .fna     : $MISSING"
echo "  Total expected   : 89"

# sanity check 
ACTUAL=$(ls "$SYMLINK_DIR"/*.fna 2>/dev/null | wc -l)
echo ""
echo "Files now in $SYMLINK_DIR: $ACTUAL"
if [ "$ACTUAL" -ne 89 ]; then
    echo "WARNING: expected 89, got $ACTUAL — check KEEP_LIST and ASSEMBLY_DIR"
fi
