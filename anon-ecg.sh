#!/bin/bash

# Function to deidentify a single XML file and write to output dir
deidentify_file() {
  local infile="$1"
  local outdir="$2"
  local base=$(basename "$infile")
  local outfile="$outdir/deid_$base"

  echo "De-identifying: $infile"
  echo "Saving to: $outfile"
  
  awk '
  BEGIN { print "Script started" > "/dev/stderr" }
  /<PatientDemographics>/ {
    print "Found <PatientDemographics>" > "/dev/stderr"
    print $0
    print "hello world"
  }
  END { print "Script ended" > "/dev/stderr" }
  ' "$infile" > "$outfile"
  
  echo "hello world" > "$outfile"

  awk '
  /<PatientDemographics>/ {
    print "Found <PatientDemographics>" > "/dev/stderr"
    print "hello world"
    fflush()  # Flush output buffer
  }
  ' "$infile" > "$outfile"

  echo "try"
  
  xmlstarlet ed \
    -u "//*[local-name()='id' and @extension]" -v "" \
    -u "//*[local-name()='birthTime']/@value" -v "" \
    "$infile" > "$outfile"
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
