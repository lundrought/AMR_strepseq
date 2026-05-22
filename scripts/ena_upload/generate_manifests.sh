#!/bin/bash

SAMPLENAMES="samplenames.txt"
FASTQ_DIR="/home/projects2/strepseq_rmarvig/fastq"
OUTPUT_DIR="manifest_files"
STUDY="PRJEB110630"
DESCRIPTION="Whole-genome sequencing based taxonomic characterisation and AMR gene detection in oral Streptococcus isolates from non-hospitalised adults"
 
mkdir -p "$OUTPUT_DIR"

count=0
errors=0

while IFS= read -r sample_alias || [[ -n "$sample_alias" ]]; do
    # Skip empty lines
    [[ -z "$sample_alias" ]] && continue
 
    # Derive the FASTQ name: replace CMPN001_ with CMPN001x
    fastq_name="${sample_alias/CMPN001_/CMPN001x}"
 
    r1="${fastq_name}_R1.fastq.gz"
    r2="${fastq_name}_R2.fastq.gz"
 
    # Warn if FASTQ files are missing (non-fatal — manifest is still written)
    if [[ ! -f "${FASTQ_DIR}/${r1}" ]]; then
        echo "WARNING: R1 not found: ${FASTQ_DIR}/${r1}"
        ((errors++))
    fi
    if [[ ! -f "${FASTQ_DIR}/${r2}" ]]; then
        echo "WARNING: R2 not found: ${FASTQ_DIR}/${r2}"
        ((errors++))
    fi
 
    out_file="${OUTPUT_DIR}/${sample_alias}.json"
 
    cat > "$out_file" <<EOF
{
  "study": "${STUDY}",
  "sample": "${sample_alias}",
  "name": "${fastq_name}",
  "platform": "ILLUMINA",
  "instrument": "Illumina NovaSeq X Plus",
  "libraryName": "Hackflex",
  "library-source": "GENOMIC",
  "library-selection": "RANDOM",
  "libraryStrategy": "WGS",
  "description": "${DESCRIPTION}",
  "fastq": [
    {
      "value": "${r1}",
      "attributes": {
        "read_type": "paired"
      }
    },
    {
      "value": "${r2}",
      "attributes": {
        "read_type": "paired"
      }
    }
  ]
}
EOF
 
    ((count++))
 
done < "$SAMPLENAMES"
 
echo ""
echo "Done. Generated ${count} manifest(s) in '${OUTPUT_DIR}/'."
if [[ $errors -gt 0 ]]; then
    echo "WARNING: ${errors} FASTQ file(s) were not found on disk — check paths above."
fi
