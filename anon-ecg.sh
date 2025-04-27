#!/bin/bash

# Function to deidentify a single XML file and write to output dir
deidentify_file() {
  local infile="$1"
  local outdir="$2"
  local base=$(basename "$infile")
  local outfile="$outdir/deid_$base"

  echo "De-identifying: $infile"
  echo "Saving to: $outfile"
  
  # Temporary file to hold intermediate processing
  local temp_file=$(mktemp)
  
  # Remove all content between <PatientDemographics> and </PatientDemographics>, keeping the tags
  sed '/<PatientDemographics>/,/<\/PatientDemographics>/ {
    /<PatientDemographics>/b
    /<\/PatientDemographics>/b
    d
  }' "$infile" > "$temp_file"

  xmlstarlet ed \
    -u "//*[local-name()='id' and @extension]" -v "" \
    -u "//*[local-name()='birthTime']/@value" -v "" \
    "$infile" > "$outfile"

  # Clean up temporary file
  rm -f "$temp_file"
}

# Function to loop through all XML files in the input directory
deidentify_directory() {
  local indir="$1"
  local outdir="$2"

  # Create output directory if it doesn't exist
  mkdir -p "$outdir"

  shopt -s nullglob
  for file in "$indir"/*.xml; do
    deidentify_file "$file" "$outdir"
  done
}

# Usage check
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_directory> <output_directory>"
  exit 1
fi

# Run de-identification
deidentify_directory "$1" "$2"
