#!/bin/bash

USERNAME="Webin-70884"          
PASSWORD="x" 
CENTER_NAME="RHGENOMICS"    
WEBIN_JAR="./webin-cli-9.0.3.jar" 
MANIFEST_DIR="./manifest_files"            
FASTQ_DIR="../fastq"   
OUTPUT_DIR="./output"                  
MODE="validate"                             # Options: test, validate, submit
 

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
 
# Count total manifests
TOTAL=$(ls "$MANIFEST_DIR"/*.json 2>/dev/null | wc -l)
echo "Found $TOTAL manifest files to process"
echo "Mode: $MODE"
echo ""

# Loop through each manifest file
COUNTER=0
for manifest_file in "$MANIFEST_DIR"/*.json; do
    COUNTER=$((COUNTER + 1))
    
    # Get just the filename without path
    manifest_name=$(basename "$manifest_file")
    
    echo "[$COUNTER/$TOTAL] Submitting: $manifest_name"
    
    # Run webin-cli
    java -jar "$WEBIN_JAR" \
        -context reads \
        -userName "$USERNAME" \
        -password "$PASSWORD" \
        -centerName "$CENTER_NAME" \
        -manifest "$manifest_file" \
        -inputDir "$FASTQ_DIR" \
        -outputDir "$OUTPUT_DIR" \
        -$MODE
    
    # Check if successful
    if [ $? -eq 0 ]; then
        echo "SUCCESS: $manifest_name"
    else
        echo "FAILED: $manifest_name"
    fi
    
    echo ""
done
 
echo "Completed! Processed $COUNTER samples"
echo "Check output directory: $OUTPUT_DIR"

 
