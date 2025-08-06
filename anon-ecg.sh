#!/bin/bash

# Function to deidentify a single XML file and write to output dir
deidentify_file() {
  local infile="$1"
  local outdir="$2"
  local base=$(basename "$infile")
  local outfile="$outdir/deid_$base"

  echo "De-identifying: $infile"
  echo "Saving to: $outfile"

  xmlstarlet ed \
  -u "//*[local-name()='id' and @extension]" -v "" \
  -u "//*[local-name()='birthTime']/@value" -v "" \
  "$infile" > "${outfile}.tmp"
  
  # Remove PHIs
  sed '/<PatientID>/d;/<PatientLastName>/d;/<PatientFirstName>/d;/<HISAccountNumber>/d;/<ExtraADTData1>/d' "${outfile}.tmp" > "${outfile}"

  # Clean up temporary file
  rm -f "${outfile}.tmp"

  # Extract values for renaming
  fname_initial=$(grep -oPm1 "(?<=<PatientFirstName>)[A-Za-z]" "$infile")
  lname_initial=$(grep -oPm1 "(?<=<PatientLastName>)[A-Za-z]" "$infile")
  date=$(grep -oPm1 "(?<=<AcquisitionDate>)[0-9]{2}-[0-9]{2}-[0-9]{4}" "$infile")
  time=$(grep -oPm1 "(?<=<AcquisitionTime>)[0-9]{2}:[0-9]{2}" "$infile" | tr -d ':')

  if [[ -n "$fname_initial" && -n "$lname_initial" && -n "$date" && -n "$time" ]]; then
    newname="${fname_initial^^}${lname_initial^^}_${date}_${time}.xml"
    mv "$outfile" "$outdir/$newname"
    echo "Renamed to: $newname"
  else
    echo "Warning: Missing tag for renaming in $infile"
  fi

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
