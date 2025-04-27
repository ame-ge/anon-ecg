#!/bin/bash

# Function to check if we can write to a file ame
check_write_access() {
  local infile="$1"
  
  # Try writing "Hello World" to the file
  echo "Hello World" > "$infile"
  
  # Check if the write was successful
  if [ $? -eq 0 ]; then
    echo "Write access confirmed for: $infile"
    return 0  # Success
  else
    echo "Error: No write access to $infile"
    return 1  # Failure
  fi
}

# Function to deidentify a single XML file and write to output dir
deidentify_file() {
  local infile="$1"
  local outdir="$2"
  local base=$(basename "$infile")
  local outfile="$outdir/deid_$base"

  echo "De-identifying: $infile"
  echo "Saving to: $outfile"


# Check write access before proceeding
check_write_access "$infile"
if [ $? -ne 0 ]; then
  echo "Skipping file due to write access error: $infile"
  return 1
fi

# Check write access before proceeding inserted by ame
  check_write_access "$infile"
  if [ $? -ne 0 ]; then
    echo "Skipping file due to write access error: $infile"
    return 1
  fi

 # Use sed to delete 2 lines after <PatientDemographics> line
  #sed '/<PatientDemographics>/ { 
    #N; 
    #N; 
    #s/\(<PatientDemographics>.*\)\n.*\n/\1/ 
  #}' "$infile" > "$outfile" # Delete the next two lines after <PatientDemographics>

  xmlstarlet ed \
  -u "//*[local-name()='id' and @extension]" -v "" \
  -u "//*[local-name()='birthTime']/@value" -v "" \
  "$outfile" > "${outfile}.tmp"
  
mv "${outfile}.tmp" "$outfile"  # Overwrite the file with the final result
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
